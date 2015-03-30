xquery version "1.0-ml";
 
module namespace list-users = "http://list-users" ;

import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/lib/config.xqy";
import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";
import module namespace get-users = "http://get-users" at "/server/model/get-users.xqy";

declare variable $url as xs:string := "/update-user";

declare function list-users:list($msg)  {
    let $all-users :=  get-users:get() 
    let $users-list := 
        for $u in $all-users  
        where ((sec:user-get-roles($u) = $cfg:management-role) and 
               fn:not($u eq xdmp:get-current-user()) and 
               fn:not($u eq $cfg:management-role))
        order by $u ascending
        return  <p><a href="{$url}/{$u}">{$u}</a><br /></p>
    let $links :=  <p><a class="makebutton"  href="/create-account-form">Create New Account</a></p>
    let $html := 
    <div class="grid-40 prefix-30 suffix-30 mobile-prefix-10 mobile-grid-80 mobile-suffix-10">
        {$msg}
        <h2>Users</h2>
        <p>Click a user id below to update that users password or click the Create New Account link to add a dev user.</p>
        {$links}{
        
            if(fn:count($users-list) le 0) then 
                <i>No users to manage</i>
            else
                $users-list
        
        }
   </div>
    return  render-view:display("User Administration", if($cfg:create-user) then $html else <div/>)
};

declare function list-users:list(){
    list-users:list("")
};