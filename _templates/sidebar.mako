<div id="sidebar" class="sidebar section">
  <h3>Me</h3>
  <ul>
    <li><a href="http://twitter.com/${bf.config.twitter_username}/">Twitter</a></li>
    <li><a href="http://github.com/${bf.config.github_username}/">Github</a></li>
    <li><a href="${bf.config.linkedin_url}">Linkedin</a></li>
    <li><a href="${bf.config.cv_url}">CV</a></li>
  </ul>
  <h3>Blog Archive</h3>
  <ul>
% for post in bf.config.blog.posts[:10]:
    <li><a href="${post.path}">${post.title}</a></li>
% endfor
  </ul>
  <h3>Subscribe</h3>
  <ul>
    <li><a href="${bf.config.rss_url}">Site RSS</a></li>
  </ul>
  <h3>Categories</h3>
  <ul>
% for category, num_posts in bf.config.blog.all_categories:
    <li>
      <a href="${category.path}">${category}&nbsp;(${num_posts})</a><!--a href="${category.path}/feed">rss</a-->
    </li>
% endfor
  </ul>
</div>