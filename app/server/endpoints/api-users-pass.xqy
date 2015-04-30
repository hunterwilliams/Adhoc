xquery version "1.0-ml";

import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

import module namespace cd = "http://marklogic.com/data-explore/lib/check-database-lib" at "/server/lib/check-database-lib.xqy" ;
import module namespace check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;

declare function local:update-password(){
    cd:check-database(),
    let $user-id := xdmp:get-current-user()
    let $password := xdmp:get-request-field("newpassword")  
    let $password2 := xdmp:get-request-field("newpasswordconfirm")
    
    return
    if(check-user-lib:is-user($user-id)) then
        if (local:isPasswordsMatch($password, $password2))
        then 
            try {
                let $_ := 
                    sec:user-set-password(
                        $user-id,
                        $password
                    ) 
               return xdmp:set-response-code(200, 'Successfully Changed Password')
           } catch ($e) {
                (xdmp:log($e),
                xdmp:set-response-code(500,'Password Update Failed'))
           }
        else (
            xdmp:set-response-code(400, fn:concat('Passwords do not match:',$password,":",$password2,"#"))
        )
    else
        xdmp:set-response-code(401,'Cant edit other users')
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


