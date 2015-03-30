xquery version "1.0-ml";

(: Security Install Script for User Management App :)

declare namespace local = "local";

declare function local:eval($num,$message,$secUtils as xs:string,$query) {

    let $log := text{' let $log := xdmp:log("    ----',$num,'. ',$message,' ---") '}
    let $done := text{'    Done ',$num, '. ', $message }
    let $queryString := text{
'xquery version "1.0-ml";
',$secUtils, $log ,$query, 'return "', $done, '"'}
    return
    xdmp:eval($queryString,(),
   <options xmlns="xdmp:eval">
     <database>{xdmp:security-database()}</database>
   </options>)

};



declare variable $secUtils as xs:string :=  
'import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare namespace local = "local";
declare function local:create-role(
    $role-name as xs:string,
    $description as xs:string?,
    $role-names as xs:string*,
    $permissions as element(sec:permission)*,
    $collections as xs:string* ) {
    try {
        sec:create-role($role-name,$description,$role-names,$permissions,$collections)
    } catch ($e) {
        xdmp:log(text{"Failed to create role (may already exist): ",$role-name})
    }
};
declare function local:remove-role($role-name) {
    try {
        sec:remove-role($role-name)
    } catch ($e) {
        xdmp:log(text{"Failed to remove role (may not exist): ",$role-name})
    }
};

declare function local:create-privilege(
    $privilege-name as xs:string,
    $path as xs:string,
    $role-names as xs:string*
) {
    try {
            sec:create-privilege($privilege-name, 
                 $path, 
                 "uri", 
                 $role-names)
    } catch ($e) {
        xdmp:log(text{"Failed to add URI priv (may exist): ",$privilege-name})
    }
};

declare function local:create-exec-privilege(
    $privilege-name as xs:string,
    $action as xs:string,
    $role-names as xs:string*
) {
    try {
            sec:create-privilege($privilege-name, 
                 $action, 
                 "execute", 
                 $role-names)
    } catch ($e) {
        xdmp:log(text{"Failed to add Exec priv (may exist): ",$privilege-name})
    }
};

declare function local:remove-privilege(
    $path as xs:string
)   {
    try {
            sec:remove-privilege(
                 $path, 
                 "uri")
    } catch ($e) {
        xdmp:log(text{"Failed to remvoe URI priv (may not exist): ",$path})
    }
};

declare function local:role-set-default-permissions(
    $role-name as xs:string,
    $permissions as element(sec:permission)*
) {
    try {
            sec:role-set-default-permissions(
                 $role-name, 
                 $permissions)
    } catch ($e) {
        xdmp:log(text{"Failed to set role permissions URI priv (role may not exist): ",$role-name})
    }
};

declare function local:add-exec-priv-to-role(
    $role-name as xs:string,
    $action as xs:string
) {
    try {
            sec:privilege-add-roles(
                 $action, 
                 "execute",($role-name))
    } catch ($e) {
        xdmp:log(text{"Failed to set execute priv action (role may not exist): ",$role-name," ",$action})
    }
};

declare function local:create-user(
    $user-name as xs:string,
    $description as xs:string?,
    $password as xs:string,
    $role-names as xs:string*,
    $permissions as element(sec:permission)*,
    $collections as xs:string*
) {
    try {
            sec:create-user($user-name,$description,$password,$role-names,$permissions,$collections)
    } catch ($e) {
        xdmp:log(text{"Failed to create user (user may already exist): ",$user-name})
    }
};

declare function local:remove-user(
    $user-name as xs:string
) {
    try {
            sec:remove-user($user-name)
    } catch ($e) {
        xdmp:log(text{"Failed to remove user (user may not exist): ",$user-name})
    }
};

 
';


declare function local:clean(){(
"START Install Cleanup (Security)",
xdmp:log(""),
xdmp:log("START Install Cleanup (Security)"),

(: //////////////// SET UP /////////////// :)
 
   
    
    local:eval('1','clean install only users',$secUtils,'
        let $REMOVE_USER := local:remove-user("mlum-install")
    '),


"END Install Cleanup (Security)",
xdmp:log("END Install Cleanup (Security)"),
xdmp:log("")
)};



local:clean()



          

