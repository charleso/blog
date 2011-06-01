<%inherit file="base.mako" />
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" 
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    ${self.head()}
  </head>
  <body>
    <div id="outer-wrapper">
    <div id="wrap2">
      ${self.header()}
      <div id="content-wrapper">
        <div id="main-wrapper">
          <div id="main" class="main section">
          ${next.body()}
          </div>
        </div><!-- End Prose Block -->
        <div id="sidebar-wrapper">
        ${self.sidebar()}
        </div>
        <div class="clear">&nbsp;</div>
      </div><!-- End Main Block -->
      <div id="footer">
        ${self.footer()}
      </div> <!-- End Footer -->
    </div> <!-- End Content -->
    </div>
  </body>
</html>
<%def name="head()">
  <%include file="head.mako" />
</%def>
<%def name="header()">
  <%include file="header.mako" />
</%def>
<%def name="footer()">
  <%include file="footer.mako" />
</%def>
<%def name="sidebar()">
  <div class="right_sidebar">
    <%include file="sidebar.mako"  args="posts=posts" />
  </div>
</%def>
