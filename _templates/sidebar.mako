<div id="sidebar" class="sidebar section">
  <h3>Blog Archive</h3>
  <ul>
% for post in bf.config.blog.posts[:10]:
    <li><a href="${post.path}">${post.title}</a></li>
% endfor
  </ul>
  <h3>Subscribe</h3>
  <a href="${bf.util.site_path_helper(bf.config.blog.path,'feed')}">Site RSS</a>
</div>