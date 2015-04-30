xquery version "1.0-ml";

module namespace check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" ;

import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";

declare function check-user-lib:is-admin() as xs:boolean
{
  let $current-user := xdmp:get-current-user()
  let $user-roles := sec:user-get-roles($current-user)
  let $is-admin := ($user-roles = $cfg:admin)
  return $is-admin
};

declare function check-user-lib:is-explorer() as xs:boolean {
    let $current-user := xdmp:get-current-user()
    let $user-roles := sec:user-get-roles($current-user)
    return
    if ($user-roles = $cfg:app-role)
            then fn:true()
            else fn:false()
};


declare function check-user-lib:is-user($user-id as xs:string) as xs:boolean {
    (check-user-lib:is-admin()) or ($user-id = xdmp:get-current-user())
};

declare function check-user-lib:is-logged-in(){
    let $config := admin:get-configuration()
    let $default-user := admin:appserver-get-default-user($config, xdmp:server())
    let $current-user := xdmp:user(xdmp:get-current-user())
    let $is-logged-in := if ($default-user = $current-user) then fn:false() else fn:true()
    return $is-logged-in
};


declare function check-user-lib:get-user-id($user-name as xs:string) {
    sec:uid-for-name($user-name)
};