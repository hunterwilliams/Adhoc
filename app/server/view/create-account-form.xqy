xquery version "1.0-ml";

import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";

render-view:display("Create User Account",
<div id="stylized" class="myform grid-40 prefix-30 suffix-30 mobile-prefix-10 mobile-grid-80 mobile-suffix-10">
  <h1>Create User Account</h1>
  <p>Use the form below to create a user account.</p> 
  <div id="logincontainer">
  <form method="post" name="sendRequestForm" id="sendRequestForm" action="/create-account">
   <dl>
        <dt><label for="user-id">User Name:</label></dt>
        <dd><input name="user-id" type="text"  size="30" /><br/></dd>
        <dt><label for="password">Password:</label><br/></dt>
        <dd><input name="password" type="password" id="password" size="30" /><br/></dd>
        <dt><label for="password2">Re-enter Password:</label><br/></dt>
        <dd><input name="password2" type="password" id="password2" size="30" /><br/></dd>
    </dl>
    <div class="submitrow">
        <input class="makebutton" id="loginbutton" type="submit" value="Create User" title="Create User"/>
    </div>
  </form>
  </div>
</div>)  