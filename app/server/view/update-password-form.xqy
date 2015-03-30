xquery version "1.0-ml";

module namespace upf = "http://update-password-form" ;

import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";

declare function upf:show-form($user-id){
    render-view:display("Update Password",
        <div id="stylized" class="myform grid-40 prefix-30 suffix-30 mobile-prefix-10 mobile-grid-80 mobile-suffix-10">
          <h1>Update Password</h1>
          <p>Use the form below to update the password.</p>
          <div id="logincontainer">
          <form method="post" name="sendRequestForm" id="sendRequestForm" action="/update-password">
          <dl>
                <dt><label for="user-id-disp">User Name:</label></dt>
                <dd>
                    <input name="user-id-disp"  type="text"  size="30" value="{$user-id}" disabled="disabled"/>
                    <input name="user-id" id="user-id"  type="hidden" value="{$user-id}" />
                    <br/>
                </dd>
                <dt><label for="password">New Password:</label><br/></dt>
                <dd><input name="password" type="password" id="password" size="30" /><br/></dd>
                <dt><label for="password2">Re-enter New Password:</label><br/></dt>
                <dd><input name="password2" type="password" id="password2" size="30" /><br/></dd>
            </dl>
            <div class="submitrow">
                <input class="makebutton" id="loginbutton" type="submit" value="Update Password" title="Update Password"/>
            </div>
          </form>
          </div>
        </div>)  
};
