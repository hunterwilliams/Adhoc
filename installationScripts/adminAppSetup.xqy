        xquery version "1.0-ml";
        
        import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
        import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
        
        declare namespace l = "local";
        declare namespace db = "http://marklogic.com/xdmp/database";
        
        declare function l:log($is) {
            xdmp:log(text{"    DB setup: " ,$is})
        };
        
        declare function l:eval($num,$message,$utils as xs:string,$query) {
        
            let $log := text{' let $log := xdmp:log("    ----',$num,'. ',$message,' ---") '}
            let $done := text{'    Done ',$num, '. ', $message }
            let $queryString := text{
        'xquery version "1.0-ml";
        ',$utils, $log ,$query, 'return "', $done, '"'}
            return
            xdmp:eval($queryString)
        
        };
        
        (: create a new forest, new db and attach them.  Hardcodes "Schema" and "Security" DBs :)
        declare function l:create-db-with-forest($database-name, $forest-names as xs:string*) {
            let $log := xdmp:log(text{"l:create-db-with-forest -- ",$database-name," ",$forest-names})
            let $config := admin:get-configuration()
            let $_ := for $forest-name in $forest-names
                return
              try {xdmp:set( $config, admin:forest-create($config, $forest-name, xdmp:host(), ()))}
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
        
        declare function l:assign-trigger-db($config, $dbid,$triggers-dbid) {
            let $log := xdmp:log(text{"l:assign-trigger-db : ",$dbid," ",$triggers-dbid})
            let $config :=
              try {admin:database-set-triggers-database(
                    $config,
                    $dbid,
                    $triggers-dbid)}
              catch ($e) {(xdmp:log("not setting Triggers database (may already be set)"), $config)}
            let $save := admin:save-configuration($config)
            return ()
        };
        
        declare function l:add-range-index(
                $config as element(configuration),
                $dbid as xs:unsignedLong,
                $type as xs:string,
                $ns as xs:string,
                $e-name as xs:string,
                $range-value-positions as xs:boolean,
                $col as xs:string)
          as element(configuration)
        {
            let $log := xdmp:log(text{"l:add-range-indexes ",$e-name})
            (:let $collation := if ($col) then $col else "http://marklogic.com/collation/":)
            let $idx := admin:database-range-element-index($type, $ns, $e-name, $col, $range-value-positions )
            let $config :=
                try { admin:database-add-range-element-index($config, $dbid, $idx) }
                catch ($e) {xdmp:log(text{"    unable to create", $e-name, "index.  may already exist"}), $config}
            let $save :=  admin:save-configuration($config)
            return $config
        };
        
        declare function l:add-range-indexes(
                $config as element(configuration),
                $dbid as xs:unsignedLong,
                $type as xs:string,
                $ns as xs:string,
                $e-names as xs:string*,
                $range-value-positions as xs:boolean,
                $col as xs:string)
          as element(configuration)
        {
        
            let $log := xdmp:log(text{"l:add-range-indexes ",$e-names})
            (:let $collation := if ($col) then $col else "http://marklogic.com/collation/":)
            let $idxes :=
                for $e-name in $e-names
                return
                admin:database-range-element-index($type, $ns, $e-name, $col, $range-value-positions )
            let $config :=
                try { admin:database-add-range-element-index($config, $dbid, $idxes) }
                catch ($e) {xdmp:log(text{"    unable to create", $e-names, "index.  may already exist"}), $config}
            let $save :=  admin:save-configuration($config)
            return $config
        };
        
        declare function l:add-attribute-range-index(
            $config as element(configuration),
            $dbid as xs:unsignedLong,
            $type as xs:string,
            $p-ns as xs:string,
            $p-name as xs:string,
            $l-ns as xs:string,
            $l-name as xs:string,
            $range-value-positions as xs:boolean,
            $col as xs:string )
        {
            let $log := xdmp:log(text{"l:add-attribute-range-index ", $p-name," ", $l-name})
            let $idx := (admin:database-range-element-attribute-index($type, $p-ns, $p-name, $l-ns, $l-name, $col, $range-value-positions ))
            let $config :=
                try { admin:database-add-range-element-attribute-index($config, $dbid, $idx) }
                catch ($e) {xdmp:log(text{"    unable to create", $p-name, "index.  may already exist"}), $config}
            let $save :=  admin:save-configuration($config)
            return $config
        };
        
        declare function l:add-element-word-lexicons(
            $config as element(configuration),
            $dbid as xs:unsignedLong,
            $namespace as xs:string,
            $localnames as xs:string*,
            $collation as xs:string )
        {
            let $log := xdmp:log(text{"l:add-element-word-lexicon ", $localnames})
            let $lexes := for $localname in $localnames return admin:database-element-word-lexicon($namespace,$localname,$collation)
            let $config :=
                try { admin:database-add-element-word-lexicon($config, $dbid, $lexes) }
                catch ($e) {xdmp:log(text{"    unable to create", $localnames, "lexicon.  may already exist"}), $config}
            let $save :=  admin:save-configuration($config)
            return $config
        };
        
        declare function l:add-word-query-excluded-element(
            $config as element(configuration),
            $dbid as xs:unsignedLong,
            $namespace as xs:string,
            $localnames as xs:string*)  as   element(configuration)
        {
            let $log := xdmp:log(text{"l:add-word-query-excluded-element ", $localnames})
            let $exclusions := for $localname in $localnames return admin:database-excluded-element($namespace,$localname)
            let $config :=
                try { admin:database-add-word-query-excluded-element($config, $dbid, $exclusions) }
                catch ($e) {xdmp:log(text{"    unable to add word query exclusions", $localnames, ".  may already exist"}), $config}
            let $save :=  admin:save-configuration($config)
            return $config
        };
        
        declare function l:add-word-query-included-element(
            $config as element(configuration),
            $dbid as xs:unsignedLong,
            $namespace as xs:string,
            $localnames as xs:string*)  as   element(configuration)
        {
            let $log := xdmp:log(text{"l:add-word-query-included-element ", $localnames})
            let $inclusions := for $localname in $localnames return admin:database-included-element($namespace,$localname,2,"","","")
            let $config :=
                try { admin:database-add-word-query-included-element($config, $dbid, $inclusions) }
                catch ($e) {xdmp:log(text{"    unable to add word query inclusions", $localnames, ".  may already exist"}), $config}
            let $save :=  admin:save-configuration($config)
            return $config
        };
        
        
        
        declare function l:database-add-geospatial-element-child-index(
            $config as element(configuration),
            $dbid as xs:unsignedLong,
            $parent-namespace as xs:string,
            $parent-localname as xs:string,
            $namespace as xs:string,
            $localname as xs:string,
            $coordinate-system as xs:string,
            $range-value-positions as xs:boolean) as element(configuration) {
        
            let $log := xdmp:log("database-add-geospatial-element-child-index")
            let $index := admin:database-geospatial-element-child-index(
                            $parent-namespace, $parent-localname, $namespace,
                            $localname, $coordinate-system, $range-value-positions) 
            let $config := 
                try { 
                    admin:database-add-geospatial-element-child-index($config, $dbid, $index)
                } catch ($e) {
                    xdmp:log(
                        text{"    unable to add geospatial child: ", $parent-localname,
                            $localname, ".  may already exist"}), $config}
            
            return $config
        };
        
        declare function l:database-add-geospatial-attribute-pair-index(
            $config as element(configuration),
            $dbid as xs:unsignedLong,
        	$parent-namespace as xs:string?,
        	$parent-localname as xs:string,
        	$latitude-namespace as xs:string?,
        	$latitude-localname as xs:string,
        	$longitude-namespace as xs:string?,
        	$longitude-localname as xs:string,
        	$coordinate-system as xs:string,
        	$range-value-positions as xs:boolean 
        ) as element(configuration) {
        	let $log := xdmp:log("database-add-geospatial-attribute-pair-index")
        	let $geospec :=  
        		admin:database-geospatial-element-attribute-pair-index(
        			$parent-namespace, $parent-localname,
        			$latitude-namespace, $latitude-localname,
        			$longitude-namespace, $longitude-localname,
        			$coordinate-system, $range-value-positions)
        	let $config :=
        		try { admin:database-add-geospatial-element-attribute-pair-index($config, $dbid, $geospec) }
        		catch ($e) {xdmp:log(text{"    unable to add geospatial attribute pair: ", $parent-localname," ",$latitude-localname," ",$longitude-localname,".  may already exist"}), $config}
        	
        	return $config
        };
        
        
        declare function l:database-add-geospatial-element-pair-index(
            $config as element(configuration),
            $dbid as xs:unsignedLong,
            $parent-namespace as xs:string,
            $parent-localname as xs:string,
            $latitude-namespace as xs:string,
            $latitude-localname as xs:string,
            $longitude-namespace as xs:string,
            $longitude-localname as xs:string,
            $coordinate-system as xs:string,
            $range-value-positions as xs:boolean) as   element(configuration) {
        
            let $log := xdmp:log("database-add-geospatial-element-pair-index")
            let $index := 
                admin:database-geospatial-element-pair-index(
                    $parent-namespace, $parent-localname, $latitude-namespace,
                    $latitude-localname, $longitude-namespace, $longitude-localname,
                    $coordinate-system, $range-value-positions)
            let $config :=
                try { admin:database-add-geospatial-element-pair-index($config, $dbid, $index) }
                catch ($e) {xdmp:log(text{"    unable to add geospatial pair: ", $parent-localname," ",$latitude-localname," ",$longitude-localname,".  may already exist"}), $config}
            
            return $config
            
        };
        
        
        declare function l:database-add-geospatial-element-index(
            $config as element(configuration),
            $dbid as xs:unsignedLong,
            $element-namespace as xs:string,
            $element-localname as xs:string,
            $coordinate-system as xs:string,
            $range-value-positions as xs:boolean,
            $point-format as xs:string) as   element(configuration) {
        
            let $log := xdmp:log("database-add-geospatial-element-pair-index")
            let $index := 
                admin:database-geospatial-element-index(
                   $element-namespace,
                   $element-localname, 
                   $coordinate-system, 
                   $range-value-positions, 
                   $point-format)
                
            let $config :=
                try { admin:database-add-geospatial-element-index($config, $dbid, $index) }
                catch ($e) {xdmp:log(text{"    unable to add geospatial element: ", $element-localname,".  may already exist"}), $config}
            
            return $config
            
        };
            
            
            
            
        
        declare function l:database-add-geospatial-element-attribute-pair-index(
            $config as element(configuration),
            $dbid as xs:unsignedLong,
            $parent-namespace as xs:string,
            $parent-localname as xs:string,
            $latitude-namespace as xs:string,
            $latitude-localname as xs:string,
            $longitude-namespace as xs:string,
            $longitude-localname as xs:string,
            $coordinate-system as xs:string,
            $range-value-positions as xs:boolean)  as   element(configuration)
        {
            let $log := xdmp:log(text{"l:database-add-geospatial-element-attribute-pair-index ", $parent-localname," ",$latitude-localname," ",$longitude-localname})
            let $index :=  admin:database-geospatial-element-attribute-pair-index(
                $parent-namespace,
                $parent-localname,
                $latitude-namespace,
                $latitude-localname,
                $longitude-namespace,
                $longitude-localname,
                $coordinate-system,
                $range-value-positions)
            let $config :=
                try { admin:database-add-geospatial-element-attribute-pair-index($config, $dbid, $index) }
                catch ($e) {xdmp:log(text{"    unable to add geospatial pair: ", $parent-localname," ",$latitude-localname," ",$longitude-localname,".  may already exist"}), $config}
            let $save :=  admin:save-configuration($config)
            return $config
        };
        
        declare function l:getSecUserId($user_name, $option) as xs:unsignedLong {
            xdmp:eval(fn:concat('
            xquery version "1.0-ml";
            import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
            sec:uid-for-name("',$user_name,'")'), (), $option)
        };
        
        declare function l:get-security-priv($action, $kind) as element(sec:privilege)? {
            xdmp:eval('
                xquery version "1.0-ml";
                import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
                declare variable $action external;
                declare variable $kind external;
                sec:get-privilege($action, $kind)
            ', (xs:QName("action"), $action, xs:QName("kind"), $kind),
            <options xmlns="xdmp:eval">
                <database>{xdmp:security-database()}</database>
            </options>)
        };
        
        declare function l:set-server-privilege($config, $appserver-id, $action, $kind) {
            try {
                let $priv := l:get-security-priv($action,$kind)
                let $_ := xdmp:log(xdmp:quote($priv),"debug")
                return
                    admin:appserver-set-privilege(
                        $config,
                        $appserver-id,
                        $priv/sec:privilege-id
                    ) 
            } catch ($e) {
                xdmp:log("priv setting did not work","error"),
                xdmp:log(xdmp:quote($e),"error"),
                $config
            }
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
            
            (: examples of other types....
            let $config := l:add-range-index($config, $content-dbid, "int", "http://framework/model/doc",      "primary-year", fn:false(), "")
            let $config := l:add-range-index($config, $content-dbid, "date", "http://framework/model/doc",      "primary-date", fn:false(), "")
            let $config := l:add-range-index($config, $content-dbid, "dateTime", "http://framework/model/doc",  "primary-dateTime", fn:false(), "")
            
            let $config := l:database-add-geospatial-element-index($config, $content-dbid, "http://framework/model/doc", "point", "wgs84", fn:false(), "point")
            :)
            
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
                    "mlum-get",
                    "http://get-log",
                    "/model/get-log.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                let $_ := l:create-amp(
                    "mlum-get",
                    "http://get-logs",
                    "/model/get-logs.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                let $_ := l:create-amp(
                    "get-user-id",
                    "http://check-user",
                    "/lib/check-user.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                let $_ := l:create-amp(
                    "mlum-get",
                    "http://get-workspaces",
                    "/model/get-workspaces.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                    
                let $_ := l:create-amp(
                    "copy-history",
                    "http://model/copy-workspace",
                    "/model/copy-workspace.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                    
                let $_ := l:create-amp(
                    "get-text-query-doc",
                    "http://model/copy-workspace",
                    "/model/copy-workspace.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                    
                let $_ := l:create-amp(
                    "get-workspace",
                    "http://model/copy-workspace",
                    "/model/copy-workspace.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                    
                let $_ := l:create-amp(
                    "insert-workspace",
                    "http://model/copy-workspace",
                    "/model/copy-workspace.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                    
                let $_ := l:create-amp(
                    "insert-workspace",
                    "http://model/copy-workspace",
                    "/model/copy-workspace.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                    
                let $_ := l:create-amp(
                    "copy-text-query-doc",
                    "http://model/copy-workspace",
                    "/model/copy-workspace.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                    
                let $_ := l:create-amp(
                    "get-histories",
                    "http://model/copy-workspace",
                    "/model/copy-workspace.xqy",
                    "admin",
                    $modules-dbid,
                    $sec_eval_option)
                let $_ := l:create-amp(
                    "oiv-report",
                    "http://oiv-report-eval-wrapper",
                    "/view/oiv-report-eval-wrapper.xqy",
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
        
        
        
