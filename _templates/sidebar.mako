<div id="sidebar" class="sidebar section">
  <h3>Me</h3>
  <ul>
    <li><a href="http://twitter.com/${bf.config.twitter_username}/">Twitter</a></li>
    <li><a href="http://github.com/${bf.config.github_username}/">Github</a></li>
    <li><a href="http://www.linkedin.com/${bf.config.linkedin_path}/">Linkedin</a></li>
  </ul>
  <h3>Blog Archive</h3>
  <ul>
% for post in bf.config.blog.posts[:10]:
    <li><a href="${post.path}">${post.title}</a></li>
% endfor
  </ul>
  <h3>Subscribe</h3>
  <ul>
    <li><a href="${bf.util.site_path_helper(bf.config.blog.path,'feed')}">Site RSS</a></li>
  </ul>
</div>