        xquery version "1.0-ml";
        
        import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
        import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
        
        declare namespace l = "local";
        declare namespace db = "http://marklogic.com/xdmp/database";
        
        declare function l:log($is) {
            xdmp:log(text{"    DB setup: " ,$is})
        };

        (: create a new forest, new db and attach them.  Hardcodes "Schema" and "Security" DBs :)
        declare function l:create-db-with-forest($database-name, $forest-names as xs:string*,$forest-location as xs:string?) {
            let $log := xdmp:log(text{"l:create-db-with-forest -- ",$database-name," ",$forest-names})
            let $config := admin:get-configuration()
            let $_ := for $forest-name in $forest-names
                return
              try {xdmp:set( $config, admin:forest-create($config, $forest-name, xdmp:host(), $forest-location))}
              catch ($e) {(xdmp:log(text{"    skipping forest create ",$forest-name," (may already exist)"}), $config)}
        
            let $config :=
              try {admin:database-create($config, $database-name,
                             xdmp:database("Security"), xdmp:database("Schemas")) }
              catch ($e) {(xdmp:log(text{"    skipping db create ",$database-name," (may already exist)"}), $config)}
            let $save := admin:save-configuration($config)
        
            let $log := l:log(("db=",xdmp:database($database-name)))
            let $log := l:log(("forest=",xdmp:forest($forest-names)))
        
            let $_ := for $forest-name in $forest-names
                return
              try { xdmp:set($config, admin:database-attach-forest(
                    $config,
                    xdmp:database($database-name), xdmp:forest($forest-name)) )}
              catch ($e) {(xdmp:log("    skipping forest attach (may already be attacehd)"), $config)}
            let $save := admin:save-configuration($config)
        
            return ()
        };
        
        
        declare function l:create-amp(
            $local-name as xs:string,
            $namespace as xs:string,
            $document-uri as xs:string,
            $role-names as xs:string*,
            $database as xs:unsignedLong,
            $sec_option
        )   {
            let $log := xdmp:log(text{"   Creating amp: ",$local-name})
        
            let $roles-string := fn:concat('("',fn:string-join($role-names, '","' ),'")')
        
            return
            try {
            xdmp:eval(fn:concat('
        xquery version "1.0-ml";
        import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
        sec:create-amp(
            "',$namespace,'",
            "',$local-name,'",
            "',$document-uri,'",
            ',$database,',
             ',$roles-string,')
            '), (), $sec_option)
            } catch($e) { xdmp:log(text{"   Amp creation failed (may already exist): ",$local-name}) }
        };
        
        declare function l:remove-amp(
            $local-name as xs:string,
            $namespace as xs:string,
            $document-uri as xs:string,
            $database as xs:unsignedLong,
            $sec_option
        )    {
            let $log := xdmp:log(text{"   Remove amp: ",$local-name})
            return
            try {
            xdmp:eval(fn:concat('
        xquery version "1.0-ml";
        import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
        sec:remove-amp(
            "',$namespace,'",
            "',$local-name,'",
            "',$document-uri,'",
            ',$database,')
            '), (), $sec_option)
             } catch($e) { xdmp:log(text{"   Amp remove failed (may not exist): ",$local-name}) }
        };
        
        (: both the test/JUnit DB and main Content DB should have the same settings. They are defined in this function :)
        declare function l:setup-content-db($db-name) {
            let $content-dbid := xdmp:database($db-name)
            let $config := admin:get-configuration()
            let $config := admin:database-set-uri-lexicon($config, $content-dbid, true())
            
            let $config := admin:database-set-directory-creation($config, $content-dbid, "manual")
            let $config := admin:database-set-maintain-last-modified($config, $content-dbid, fn:false())
            
            let $save :=  admin:save-configuration($config)
            return ()
        };
        
        declare function l:setup() {
          (
            "START DEPLOY  DATABASE ",
            xdmp:log(""),
            xdmp:log("START DEPLOY  DATABASE"),
        
        
            "1. Create Databases",
            let $log := xdmp:log("1. Create Databases")
            let $CREATE := l:create-db-with-forest($modules-database-name, $modules-forest-name, $forest-location)
            
            return (),
            
            
        
            
            "3. Create Application HTTP Server",
            let $log := xdmp:log("3. Create Application HTTP Server")
            let $config := admin:get-configuration()
            let $group-id := admin:group-get-id($config, "Default")
            let $content-dbid := xdmp:database($content-database-name)
            let $modules-dbid := xdmp:database($modules-database-name)
            
        
            let $config :=
              try {admin:http-server-create($config, $group-id, $app-http-server-name, "/", $app-http-server-port, $modules-dbid, $content-dbid)}
              catch ($e) {(xdmp:log("skipping app-xdbc server add (may already exist)"), $config)}    
            let $save := admin:save-configuration($config)
            return (),
            
            "4. Configure App HTTP Server",
            let $log := xdmp:log("4. Configure App HTTP Server")
            let $config := admin:get-configuration()
            let $http-id := admin:appserver-get-id($config, admin:group-get-id($config, "Default"), $app-http-server-name)    
            let $user-uid := xdmp:user("mlum-default-user")
            let $config := admin:appserver-set-error-handler($config, $http-id, "/server/error.xqy")
            let $config := admin:appserver-set-url-rewriter($config, $http-id, "/server/rewrite.xqy")
            let $config := admin:appserver-set-authentication($config, $http-id, "application-level")
            let $config := admin:appserver-set-default-user($config, $http-id, $user-uid)
            
            let $exec-priv :=  xdmp:eval('
                    xquery version "1.0-ml";
                    import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy"; 
                    sec:get-privilege("http://marklogic.com/ps/ml-user-mng", "execute")/sec:privilege-id
                ', (),  $sec_eval_option)
            
            let $config := admin:appserver-set-privilege( $config, $http-id, $exec-priv ) 
            let $save := admin:save-configuration($config) 
            return 
                (),
                
            "5. Create AMPS",
            let $log := xdmp:log("5. Create AMPS")
            let $config := admin:get-configuration()
            let $modules-dbid := xdmp:database($modules-database-name)
                let $_ := l:create-amp(
                    "get-user-id",
                    "http://check-user",
                    "/lib/check-user.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                let $_ := l:create-amp(
                    "search",
                    "http://marklogic.com/ps/lib/searchyy",
                    "/lib/search.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                let $namespace-detail := "http://marklogic.com/ps/lib/detail"
                let $lib-detail-uri := "/lib/l-detail.xqy"
                let $_ := l:create-amp(
                    "get-permissions",
                    $namespace-detail,
                    $lib-detail-uri,
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                let $_ := l:create-amp(
                    "get-collections",
                    $namespace-detail,
                    $lib-detail-uri,
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                let $_ := l:create-amp(
                    "find-related-items-by-document",
                    $namespace-detail,
                    $lib-detail-uri,
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                let $_ := l:create-amp(
                    "find-related-audits-by-uri",
                    $namespace-detail,
                    $lib-detail-uri,
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                let $_ := l:create-amp(
                    "get-document",
                    $namespace-detail,
                    $lib-detail-uri,
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
            return
                ()
                
          )
        };
        
        (: ******************************************************** :)
        (: *********     PARAMETERS TO CONFIGURE     ************** :)
        (: ******************************************************** :)
            (: low end of 10 port range used for this deployment :)
            declare variable $port-number as xs:integer := 8006;
            declare variable $db-name := "MLUM";
            
            (: Set to location of forests :)
             declare variable $forest-location := ();
           (: declare variable $forest-location := fn:error(xs:QName("NO_FOREST_LOC"), "You must change this script to specify a directory for forests"); (: e.g. "F:\MarkLogic\" or () for default directory :):)
        (: ******************************************************** :)
        
        
        declare variable $name := $db-name;
        
        declare variable $sec_eval_option :=
           <options xmlns="xdmp:eval">
             <database>{xdmp:security-database()}</database>
           </options>;
        
        declare variable $content-database-name := "Security";
        declare variable $modules-database-name := concat($name, "-Modules");
        
        declare variable $modules-forest-name := $modules-database-name;
        
        declare variable $app-http-server-port as xs:integer := $port-number + 0;
        declare variable $app-http-server-name := concat($name, "-HTTP");
        
        (
        l:setup()
        ,
        fn:concat(
        '
        ')
        )
        
        
        
