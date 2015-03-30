xquery version "1.0-ml";

import module namespace list-user = "http://list-users" at "/server/view/list-users-view.xqy";
import module namespace check-user = "http://check-user" at "/server/lib/check-user.xqy" ;
import module namespace upf = "http://update-password-form" at "/server/view/update-password-form.xqy" ;
import module namespace lif = "http://login-form" at "/server/view/login-form.xqy" ;

let $current-user := xdmp:get-current-user()
return 
    if (check-user:is-admin())
    then list-user:list()
    else 
        if (check-user:is-logged-in())
        then upf:show-form($current-user)
        else lif:show-form()
    