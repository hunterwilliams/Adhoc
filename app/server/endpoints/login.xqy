xquery version "1.0-ml";
 
import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

import module namespace cd = "http://check-database" at "/server/lib/check-database.xqy" ;
import module namespace cu = "http://check-user" at "/server/lib/check-user.xqy" ;
import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";
import module namespace nav = "http://navigation" at "/server/view/nav.xqy";
import module namespace list-users = "http://list-users" at "/server/view/list-users-view.xqy";

declare function local:login(){
    cd:check-database(),
    let $user-id := xdmp:get-request-field("user-id")  
    let $password := xdmp:get-request-field("password")  
    return 
        try {
            let $isLoggedIn := xdmp:login($user-id, $password)
            return
                if ($isLoggedIn) 
                then  render-view:display("Login Result",<div class="col-md-4 col-md-offset-4">
                    <div class="alert alert-success" role="alert"><strong>Login Successful</strong> You are now logged in.</div>
                    <p><a href="/">Go to Home Page  </a> or pick one of the above options</p>
                </div>)
                else  render-view:display("Login Result",<div class="col-md-4 col-md-offset-4">
                    <div class="alert alert-danger" role="alert"><strong>Login Error</strong> Unable to log in.</div></div>)
        } catch  ( $e ) {
            render-view:display("Login Result", <div class="col-md-4 col-md-offset-4">
                    <div class="alert alert-danger" role="alert"><strong>Login Error</strong> Unable to log in.</div></div>),
            xdmp:log(fn:concat("Error", fn:string($e)))
        }
};

local:login()

