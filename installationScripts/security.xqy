xquery version "1.0-ml";

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

declare function local:remove-exec-privilege(
    $path as xs:string
)   {
    try {
            sec:remove-privilege(
                 $path, 
                 "execute")
    } catch ($e) {
        xdmp:log(text{"Failed to remvoe Exec priv (may not exist): ",$path})
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


declare function local:setup(){(
"START DEPLOY SECURITY ",
xdmp:log(""),
xdmp:log("START DEPLOY SECURITY"),

(: //////////////// SET UP /////////////// :)
 
    local:eval('1','Install Basic Roles',$secUtils,'
        let $CREATE_USER := local:create-role("data-explorer-default-user","Role for Data Explorer App",
                                    ("rest-reader","app-user"),(),())
        let $CREATE_ROLE := local:create-role("data-explorer-install","Install role for Data Explorer App",
                            ("admin"),(),())
    '),
    
    (: The following role is dependent on the readonly roles and above data-explorer-default-user:)
    local:eval('2','Install User Assign Roles',$secUtils,'
        let $CREATE_USER := local:create-role("data-explorer-user","Role for Data Explorer",
                                    ("data-explorer-default-user"),(),())
    '),
    
    local:eval('4','Set default role permissions',$secUtils,'

        let $SET_PERM := local:role-set-default-permissions("data-explorer-install",
            (xdmp:permission("data-explorer-default-user","read"),
             xdmp:permission("data-explorer-default-user","execute")))
    '),
    
    local:eval('5a','Create special exec priv',$secUtils,' 
        let $ADD_PRIV := local:create-exec-privilege("ml-data-explore","http://marklogic.com/ps/ml-data-explore",())
    '),
    
    local:eval('5b','Assign exec priv to role',$secUtils,' 
        let $ADD_PRIV := local:add-exec-priv-to-role("data-explorer-default-user","http://marklogic.com/xdmp/privileges/xdmp-invoke")
        let $ADD_PRIV := local:add-exec-priv-to-role("data-explorer-default-user","http://marklogic.com/xdmp/privileges/xdmp-invoke-in")
        let $ADD_PRIV := local:add-exec-priv-to-role("data-explorer-default-user","http://marklogic.com/xdmp/privileges/xdmp-value")
        let $ADD_PRIV := local:add-exec-priv-to-role("data-explorer-default-user","http://marklogic.com/xdmp/privileges/admin-module-read")
        let $ADD_PRIV := local:add-exec-priv-to-role("data-explorer-default-user","http://marklogic.com/xdmp/privileges/get-user-names")
        let $ADD_PRIV := local:add-exec-priv-to-role("data-explorer-default-user","http://marklogic.com/xdmp/privileges/user-set-password")
        
        
        let $ADD_PRIV := local:add-exec-priv-to-role("data-explorer-default-user","http://marklogic.com/ps/ml-data-explore")
        let $ADD_PRIV := local:add-exec-priv-to-role("data-explorer-default-user","http://marklogic.com/xdmp/privileges/xdmp-eval")
        let $ADD_PRIV := local:add-exec-priv-to-role("data-explorer-default-user","http://marklogic.com/xdmp/privileges/xdmp-eval-in")
        let $ADD_PRIV := local:add-exec-priv-to-role("data-explorer-default-user","http://marklogic.com/xdmp/privileges/any-uri")
        let $ADD_PRIV := local:add-exec-priv-to-role("data-explorer-default-user","http://marklogic.com/xdmp/privileges/xdmp-add-response-header")
        
    '),
    
    local:eval('6','create users',$secUtils,'
        let $CREATE_USER := local:create-user("data-explorer-default-user","Data Explorer Default User",fn:string(xdmp:random()),("data-explorer-default-user"),(),())
        let $CREATE_USER := local:create-user("data-explorer-install","Data Explorer Install User", "data-explorer-install",("data-explorer-install"),(),())
    '),


"END DEPLOY SECURITY",
xdmp:log("END DEPLOY SECURITY"),
xdmp:log("")
)};



local:setup()



          

