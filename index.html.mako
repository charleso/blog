<%inherit file="_templates/site.mako" />

% for post in bf.config.blog.posts[:5]:
    <%include file="post.mako" args="post=post, separator=True"/>
% if bf.config.blog.disqus.enabled:
  <div class="after_post"><a href="${post.permalink}#disqus_thread">Read and Post Comments</a></div>
% endif
% endfor

<div id="blog-pager" class="blog-pager">
  <span id="blog-pager-older-link">
    <a href="page/2">Older Posts</a>
  </span>
</div>
