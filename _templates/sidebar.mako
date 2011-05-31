<div id="sidebar" class="sidebar section">
  <h3>Blog Archive</h3>
  <ul>
% for post in bf.config.blog.posts[:10]:
    <li><a href="${post.path}">${post.title}</a></li>
% endfor
  </ul>
</div>