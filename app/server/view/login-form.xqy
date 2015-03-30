xquery version "1.0-ml";
 module namespace lif = "http://login-form";

import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/lib/config.xqy";
import module namespace  cu = "http://check-user" at "/server/lib/check-user.xqy" ;

declare function lif:show-form()
{
    render-view:display("Login",
          <form class="form-signin col-md-2 col-md-offset-5" method="post" name="sendRequestForm" id="sendRequestForm" action="/login">
            <p class="text-center"><img src="/images/MarkLogic_RGB_72ppitrans.png" /></p>
            <label for="inputEmail" class="sr-only">Username</label>
            <input type="text" id="user-id" name="user-id" class="form-control" placeholder="Username" required="" autofocus="" />
            <label for="inputPassword" class="sr-only">Password</label>
            <input type="password" id="password" name="password" class="form-control" placeholder="Password" required="" />
            
            <button class="btn btn-lg btn-primary btn-block" id="loginbutton" type="submit" title="Log in">Log in</button>
          </form>
    )
};