xquery version "1.0-ml";

import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

import module namespace cd = "http://check-database" at "/server/lib/check-database.xqy" ;
import module namespace cu = "http://check-user" at "/server/lib/check-user.xqy" ;
import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";

declare function local:update-password(){
    cd:check-database(),
    let $user-id := xdmp:get-request-field("user-id")  
    let $password := xdmp:get-request-field("password")  
    let $password2 := xdmp:get-request-field("password2")  
    
    
    return
    if(cu:is-user($user-id)) then
        if (local:isPasswordsMatch($password, $password2))
        then 
            try {
                let $_ := 
                    sec:user-set-password(
                        $user-id,
                        $password
                    ) 
               return render-view:display("Password Updated", <div><h1>Password Updated</h1><p>Password has been updated.</p></div>)
           } catch ($e) {
                xdmp:log($e),
                render-view:display("Password Update Failed", <div><h1>Password Update Failed</h1><p>Unable to update password.</p></div>)
           }
        else (
            render-view:display("Invalid Password", <div><h1>Invalid password or passwords Do Not Match</h1><p>Please retype password.</p></div>)
        )
    else
        render-view:display("Editing other users prohibited", <div><h1>Editing other users prohibited</h1><p>Please only edit your own account.</p></div>)
};  

(: add check for current password:)

declare function local:isPasswordsMatch($password, $password2) as xs:boolean {

    ($password)
    and
    ($password2)
    and
    ($password = $password2)

};

local:update-password()


