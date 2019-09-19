---
author: Charles O'Farrell
date: 2019/09/18 20:21:00
encoding: utf8
permalink: /2019/09/life-after-hadoop.html
categories: scala
title: Life After Spark
updated: 2019/09/18 20:21:00
layout: post
---

*NOTE: This is something I wrote for my team at BT, it was aimed at a specific
audience and I didn't spend the time to re-orient my arguments to suit a more
general audience*

I would like to mention up-front, that my intension is not to claim that this
approach is strictly better than Spark or vice-versa. I think we always need to
make these choices in context, and understand the tradeoffs. I'm hoping by
showing a completely different alternative some of those tradeoffs become more
obvious and in the future it might help make a different decision to Spark if,
or when, appropriate.

## Hadoop Journey

Originally at Ambiata we had some tools that were built on raw Hadoop
map/reduce. Similar to Spark, Hadoop gave us the ability to utilise AWS EMR and
rapidly prototype our ideas and serve our customers. At the time Spark was
still fairly new and unproven.

Our Hadoop journey was quite likely very similar to many other companies
running Hadoop in AWS.

Single cluster per customer. Canonical data stored on the cluster.  Realised
the precariousness of storing the data on a single Hadoop cluster and decided
to backup data on S3.  Started to introduce some jobs that weren't
Hadoop-based, and instead could be S3 → S3.  Noticed we could use transient
Hadoop clusters plus `distcp` to turn those jobs in to S3 → S3 as well.

### Ha-dont?

Around this time we ran in to two major problems that made us re-think our use
of Hadoop entirely.

#### Cost

As demand and size of the data grew the cost of EMR started to become
significant. That is we had to pay AWS extra money for the convenience of using
EMR (vs say running our own manually configured Hadoop cluster). We referred to
it as the "EMR tax".

At this point we considered deploying our own Hadoop clusters to save some of
money, but that would have likely been a _significant_ amount of work and we
would _still_ be writing/running Hadoop jobs which wasn't our idea of fun.

#### JVM Only

Separately we had also written a [tool in
Haskell/C](https://github.com/ambiata/icicle) for doing [_fast_ generation of
features](https://www.youtube.com/watch?v=ZuCRgghVR1Q), which we wanted to
start to use against our existing data. How would we run that within our Hadoop
job? [It can be done, but it's not
ideal...](https://hadoop.apache.org/docs/stable/hadoop-streaming/HadoopStreaming.html)

### S3 + Unix + Orchestration

At some point we wondered whether we could only use S3 instead of a
cluster-backed filesystem, and run unix jobs on elastic EC2 instances from an
SQS queue. We ended up implementing the queue part ourselves, but in my final
days at Ambiata I switched from that system to AWS Batch. It demonstrated
running these unix jobs could be orchestrated in different ways without having
to change a _single_ line of the actual super-important, well tested, hand
optimised data-processing code, just the "driver" glue code.

## AWS Batch

I think AWS Batch is one of the most under-appreciated services from Amazon.

AWS Batch is relatively simple (which is one of the reasons I like it). [It has
three main
components](https://aws.amazon.com/blogs/compute/using-aws-cloudformation-to-create-and-manage-aws-batch-resources/)
(direct copy+paste):

- A [job definition] specifies how jobs are to be run—for example, which Docker
  image to use for your job, how many vCPUs and how much memory is required,
  the IAM role to be used, and more.

- Jobs are submitted to [job queues] where they reside until they can be
  scheduled to run on Amazon EC2 instances within a compute environment. An AWS
  account can have multiple job queues, each with varying priority. This gives
  you the ability to closely align the consumption of compute resources with
  your organisational requirements.

- [Compute environments] provision and manage your EC2 instances and other compute
  resources that are used to run your AWS Batch jobs. Job queues are mapped to
  one more compute environments and a given environment can also be mapped to one
  or more job queues. This many-to-many relationship is defined by the compute
  environment order and job queue priority properties.

[job definition]: http://docs.aws.amazon.com/batch/latest/userguide/job_definitions.html
[job queues]: http://docs.aws.amazon.com/batch/latest/userguide/job_queues.html
[Compute environments]: http://docs.aws.amazon.com/batch/latest/userguide/compute_environments.html

At this point you write some launch jobs (pseudo code). Think of this like the
driver for Spark. It may well inspect the size/metadata of the data on S3 to
configure the parameters of some of the jobs. For one job we even implemented
our own data repartitioning with some simple [bin packing] without too much
trouble.

[bin packing]: https://en.wikipedia.org/wiki/Bin_packing_problem

```scala
val jobTransform = AWS.Batch.submitJob("docker.prd.ace/centos_6:latest", "data_queue", array_size = 50,
  "transform.sh --input s3://data/frontdoor --output s3://data/input")
val jobScore = AWS.Batch.submitJob("docker.prd.ace/python_ml:latest", "ml_queue", array_size = 100, parent = jobTransform,
  "score.py --input s3://data/input --output s3://data/score")

// Actually technically you might not want to publish like this, it should be run on a cron job instead, but just as an example
AWS.Batch.submitJob("docker.prd.ace/publish_scores:latest", "data_queue", array_size = 10, parent = jobScore,
  "publish-scores.sh --input s3://data/score")
AWS.Batch.submitJob("docker.prd.ace/python3:latest", "data_queue", array_size = 1, parent = jobScore,
  "send-email-summary.py --input s3://data/score")
```

And our tools might be anything from a simple shell script, to a full Scala
program (or both). Here is just one simple "transformation" code using a shell
script composing the aws cli with awk. Note that for "array" jobs you (only)
get passed a single index offset.

```shell
aws s3 cp "$1/${AWS_BATCH_JOB_ARRAY_INDEX}.csv" input.csv
awk -F ',' '{ print $1","$3 }' input.csv > output.csv
aws s3 cp output.csv "$2/${AWS_BATCH_JOB_ARRAY_INDEX}.csv"
```

You might then want to call a Python program for running the actual scoring, or
Spark, and after that process them with yet-another, separate Unix program.

### Known Limitations

In my brief time using AWS Batch I ran in to some noteworthy limitations that I
don't see how you could avoid/ignore if you use the service in anger.

#### Transient Metadata

Unfortunately AWS have made the decision to cleanup metadata for jobs that run
for around roughly 24 hours or so. This means that to build a production system
on top of AWS Batch you almost certainly need to store your own metadata for
each job that ran.

#### Job Retry Only

Each job that runs in AWS Batch can be configured to retry X times on failure.
This is great. But unfortunately once one job has failed due to a real problem,
the entire pipeline (eventually) fails. If you are able to "fix" what caused
that failure (ie one missing file), your only choice would be to retry the
entire pipeline. I hacked around this by running with a unique PIPELINE_RUN_ID,
and marking jobs as successful against that (with an S3 file). Each job would
check that flag and exit immediately, so that the pipeline could get back to
where it failed relatively quickly. It's not ideal.

## Tradeoffs

### Advantages

#### Elastic Cost

We saw significant savings running jobs on an elastic set of resources, rather
than having to bring up a full EMR cluster each time.

See the final links at the bottom of this post, but [Zendesk are using AWS
Batch quite successfully](https://medium.com/zendesk-engineering/the-dawn-of-zendesks-machine-learning-model-building-platform-with-aws-batch-5d3243d2d2a8#30ac):

> It was revealed by our load tests that we spent on average $3 building 1000
> ML models on AWS Batch

#### (Re)Test in Isolation

What happens if you have an error, or worse some performance/skew problem in
production? In Spark you have to orchestrate your cluster with various JMX
tools just to get an idea of what might be the problem. In this brave new Unix
world you are able to launch a new instance of the docker image and re-run the
exact command, on the exact instance type, on the exact file in S3 that breaks,
and observe the same behaviour in isolation. No need to re-run an entire job
with debugging, or copy+paste partial code from your spark application in to a
shell session to re-create the state where it fails.

#### Heterogeneous Computations

The ability to write various parts of the pipeline in different languages is
surprisingly liberating and powerful; calling an open source Python library
here, and a custom Haskell application there, all glued together with the magic
of Shell if necessary.

### Disadvantages

#### No Spark Reuse

Spark does give you many nice functions to do powerful transformation over
large data without much code. Most of that is not partially re-usable in this
new world, Spark is everything-or-nothing. That said, there's nothing stopping
you running Spark locally on each of the batch machines, although it would not
be anywhere as efficient as running a single instance of Spark on EMR.

#### You Mean I Have to Think About This Stuff?!?

In Spark it's trivial to chain multiple map/filters over a data source and
distribute the computation. Under the covers Spark does all sort of magic to
capture the map/filter computation, send it to executors along with the
appropriate data, run that code, and send the data back. In AWS Batch the lines
between the driver and the map/filter code are different programs, and the data
has to be serialised in some format on S3. For both of these steps you have to
be very deliberate.

## Why Not Both?

This is actually what we had at Ambiata. Part of our pipeline remained in
Hadoop for the entire time, and the newer ones were something else. It looks
something (like) the following. This configuration would ideally reconfigure
[Cloudwatch Events], [Step Functions], or whatever distributed (and ideally HA)
schedule service you were using.  I just made up this configuration format, but
we had something very similar written in a Haskell DSL.

[Cloudwatch Events]: https://docs.aws.amazon.com/batch/latest/userguide/batch-cwe-target.html
[Step Functions]: https://docs.aws.amazon.com/step-functions/latest/dg/connect-batch.html

```yaml
transform:
  schedule: '0 10 * * *'
  # We need a temporary EMR cluster to run our job against
  emr:
    type: 'm1.4xlarge'
    instances: 10
  batch:
    definition: docker.prd.ace/centos6:latest
    queue: data
    command: 'transform.sh --input s3://data/frontdoor --output s3://data/input'

score:
  schedule: '0 13 * * *'
  batch:
    definition: docker.prd.ace/java8:latest
    queue: data
    # Might run the pseudo code we saw above
    command: 'java -cp score_driver.jar --input s3://data/input --output s3://data/scores'

publish:
  schedule: '0 11 * * 1-5'
  batch:
    definition: docker.prd.ace/centos6:latest
    queue: data
    command: 'publish.sh --input s3://data/scores'
```

For some types of jobs we want to keep using EMR and run our Spark jobs. In
others we might want to run jobs in our compute environment, which in turn
might start/run other batch jobs.

## Simple Made Easy

One of my favourite talks is from the Clojure author Rich Hickey. Rich makes
the argument that "simple" is not the same "easy". Easy is something that "lies
near", and is _relative_ to our skills/compatibility. Simple is _objectively_
about how many things are bound together. I like to think of being simple akin
to the unix philosophy of "do one thing and do it well"

<https://www.infoq.com/presentations/Simple-Made-Easy/>

By this definition I would argue Spark is "easy". It's incredibly easy to write
a few lines of Scala code that might process your entire data pipeline. But
what happens when you want to do something outside of the current capabilities
of Spark (ie [hive bucketing at Facebook][hive_bucketing_facebook]? By Rich's
definition Spark is also complex because it "complects" (Rich's new word)
orchestrating distributed computations (something that is really, really hard)
with the computation itself, all wrapped up in a single Scala application. AWS
Batch is nowhere near as easy, but is arguably quite simple due to having few
moving parts (basically Docker definitions + job queues + ECS) but which can
build complex data pipelines to suit any requirements, and is arguably cheaper
and easier to operate at scale.

[hive_bucketing_facebook]: https://databricks.com/session/hive-bucketing-in-apache-spark)

As developers I think we to often overvalue how "easy" something is. How easy
it is to get something working. But by being easy that doesn't mean something
is simple (and vice-versa), and in fact often things that are simple are almost
always not easy to start with because they have more, smaller parts/components.
But over time that simplicity lets us build more complicated systems by
building on simple things, which can be built from other simple things etc.
That initial cost can be amortised by not having to redo something again
slightly differently every single time.

## Success Stories

Many of the explanations here mirror my own experience with AWS Batch, and this
kind of approach in general.

- NextRoll
  - <http://tech.nextroll.com/blog/data/2018/08/08/running-jobs-with-aws-batch.html>
  - <http://tech.nextroll.com/blog/data/2015/09/22/data-pipelines-docker.html>
- Zendesk
  - <https://medium.com/zendesk-engineering/how-we-use-aws-batch-at-zendesk-to-build-all-the-machine-learning-models-a41d93eabd45>
  - <https://medium.com/zendesk-engineering/the-dawn-of-zendesks-machine-learning-model-building-platform-with-aws-batch-5d3243d2d2a8>
  - <https://medium.com/zendesk-engineering/zendesk-ml-model-building-pipeline-on-aws-batch-monitoring-and-load-testing-8a7decbb5ad9>
  - [YOW! Data 2019 - Dana Ma - Building Rome Every Day - Scaling ML Model Building Infrastructure (youtube)](https://www.youtube.com/watch?v=sZo_o6IdAQo)
