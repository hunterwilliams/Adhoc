xquery version "1.0-ml";

module namespace cw = "http://model/copy-workspace" ;

declare namespace qconsole="http://marklogic.com/appservices/qconsole";

import module namespace cu = "http://check-user" at "/server/lib/check-user.xqy" ;

import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

declare variable $options := 
        <options xmlns="xdmp:eval">
            <database>{xdmp:database("App-Services")}</database> 
        </options>;


(:To avoid confusion with all the differen qc:ids, variables referring to element values follow 
this nameing convention: 
  $documenttype-xpathtoelement. 
  e.g., $workspace-queries-query-id is the value of the following element:
    <qc:workspace>
      ....
      <qc:queries>
        <qc:query>
          <qc:id>value</qc:id>
        </qc:query> 
      </qc:queries>
      .....
    </qc:workspace> :)
    
declare function cw:copy(
  $old-workspace as element (qconsole:workspace),
  $new-user-id as xs:string) {
  
  let $new-workspace-id := xdmp:wallclock-to-timestamp(fn:current-dateTime()) 
  let $new-workspace-id-node := <qconsole:id>{$new-workspace-id}</qconsole:id>
  let $new-workspace-uri := fn:concat("/workspaces/", $new-workspace-id, ".xml")
  
  let $old-workspace-id := $old-workspace/qconsole:id/fn:string()
   
  let $new-user-id-node := 
    element {fn:node-name($old-workspace/qconsole:security)} 
    {$old-workspace/qconsole:security/@*, 
    <qconsole:userid>{$new-user-id}</qconsole:userid>,
    $old-workspace/qconsole:security/node() except $old-workspace/qconsole:security/qconsole:userid}    
  
  let $updated-doc := 
    element {fn:node-name($old-workspace)} 
      {$old-workspace/@*, 
      $new-user-id-node, 
      $old-workspace/node() except $old-workspace/qconsole:security} 
      
  let $updated-doc := 
    element {fn:node-name($updated-doc)} 
      {$updated-doc/@*, 
       $new-workspace-id-node, 
      $updated-doc/node() except $updated-doc/qconsole:id} 
      
  
  let $updated-doc := cw:update-queries(
    $old-workspace-id,
    $new-workspace-id,
    $new-user-id,
    $updated-doc,
    $old-workspace)    
   
  let $_ := cw:insert-workspace($new-workspace-uri, $updated-doc)
  
  return $new-workspace-uri 
};

declare function cw:update-queries(
    $old-workspace-id as xs:string,
    $new-workspace-id as xs:unsignedLong,
    $new-user-id as xs:string,
    $updated-doc as node(), 
    $old-workspace as node()) {
    
    let $workspace-query-nodes := $old-workspace/qconsole:queries/qconsole:query
    
    let $updated-workspace-query-nodes := 
        for $wqn at $i in $workspace-query-nodes
            let $timestamp-ms := xdmp:wallclock-to-timestamp(fn:current-dateTime())
            let $new-history-query-id := fn:concat($timestamp-ms, $i, "1")
            
            let $old-history-query-id := $wqn/qconsole:id/fn:string()
            let $log := xdmp:log("$old-history-query-id")
            let $log := xdmp:log($old-history-query-id)
            let $old-user-id := $old-workspace/qconsole:security/qconsole:userid/fn:string()
            
            let $new-workspace-query-node := 
                element {fn:node-name($wqn)} 
                {$wqn/@*, 
                <qconsole:id>{$new-history-query-id}</qconsole:id>,
                $wqn/node() except $wqn/qconsole:id}  
            
            (: update history and query text documents for the query being updated :)
            let $history-docs := cw:get-histories($old-workspace-id, $old-history-query-id, $old-user-id)
            let $copy-history-doc :=
                if ($history-docs)
                then 
                    for $h at $j in $history-docs
                    let $new-history-id  := fn:concat($timestamp-ms, $i, $j, "2")
                    return 
                        cw:copy-history($h, 
                            $new-user-id, 
                            $new-workspace-id, 
                            $new-history-query-id, 
                            $new-history-id)
                else ()
            
            let $text-query-doc := cw:get-text-query-doc($old-history-query-id)
            let $copy-text-query-docs := cw:copy-text-query-doc($text-query-doc, $new-history-query-id)
            
            return $new-workspace-query-node 
            
    let $new-workspace-queries-node := 
        element {fn:node-name($updated-doc/qconsole:queries)} 
        {$updated-doc/qconsole:queries/@*, 
        $updated-workspace-query-nodes, 
        $updated-doc/node() except $updated-doc/qconsole:queries} 
            
            
    let $updated-doc := 
        element {fn:node-name($updated-doc)} 
        {$updated-doc/@*, 
        $new-workspace-queries-node, 
        $updated-doc/node() except $updated-doc/qconsole:queries} 
      
      (: return doc with query nodes updated:)
      return $updated-doc    
   
};

declare function cw:copy-history(
  $history-doc, 
  $new-user-id, 
  $new-workspace-id, 
  $new-history-query-id, 
  $new-history-id){

   let $log := xdmp:log("history doc in copy-history: ")
   let $log  := xdmp:log($history-doc)
   let $log := xdmp:log("security node:")
   let $log := xdmp:log($history-doc/qconsole:security)

  (:update with new user-id:)
  let $new-user-id-node := 
    element {fn:node-name($history-doc/qconsole:security)} 
    {$history-doc/qconsole:security/@*, 
    <qconsole:userid>{$new-user-id}</qconsole:userid>,
    $history-doc/qconsole:security/node() except $history-doc/qconsole:security/qconsole:userid}  
    
  let $history-doc := 
    element {fn:node-name($history-doc)} 
      {$history-doc/@*, 
      $new-user-id-node, 
      $history-doc/node() except $history-doc/qconsole:security} 
   
  (:update with new workspace-id:)   
  let $new-workspace-node := 
    element {fn:node-name($history-doc/qconsole:workspace)}
    {$history-doc/qconsole:workspace/@*,
    <qconsole:id>{$new-workspace-id}</qconsole:id>,
    $history-doc/qconsole:workspace/node() except $history-doc/qconsole:workspace/qconsole:id}

  let $history-doc := 
    element {fn:node-name($history-doc)} 
      {$history-doc/@*, 
      $new-workspace-node, 
      $history-doc/node() except $history-doc/qconsole:workspace}  
   
  (:update with new new-history-query-id:)   
  let $new-history-query-id-node := 
    element {fn:node-name($history-doc/qconsole:query)}
    {$history-doc/qconsole:query/@*,
    <qconsole:id>{$new-history-query-id}</qconsole:id>,
    $history-doc/qconsole:query/node() except $history-doc/qconsole:query/qconsole:id}

  let $history-doc := 
    element {fn:node-name($history-doc)} 
      {$history-doc/@*, 
      $new-history-query-id-node, 
      $history-doc/node() except $history-doc/qconsole:query}     
     
  (:update with new new-history-id:)   
  let $new-history-id-node := <qconsole:id>{$new-history-id}</qconsole:id>

  let $history-doc := 
    element {fn:node-name($history-doc)} 
      {$history-doc/@*, 
      $new-history-id-node, 
      $history-doc/node() except $history-doc/qconsole:id}     
 
  let $new-uri := fn:concat("/histories/", $new-history-id, ".xml")
  

  let $params :=  (
    xs:QName("new-uri"), $new-uri, 
    xs:QName("history-doc"),  $history-doc)
     
  let $eval := 
    'xquery version "1.0-ml";
    declare variable $new-uri as xs:string external; 
    declare variable $history-doc as node() external; 
    xdmp:document-insert($new-uri, $history-doc)'
  
    return xdmp:eval($eval, $params, $options)
   
}; 

declare function cw:get-text-query-doc($history-query-id) {

  let $params :=  (xs:QName("history-query-id"), $history-query-id)
    
  let $eval := 
    'xquery version "1.0-ml";
    declare variable $history-query-id as xs:string external; 
    let $uri := fn:concat("/queries/", $history-query-id, ".txt")
    return fn:doc($uri)'
    
    return xdmp:eval($eval, $params, $options)   
};

declare function cw:get-workspace($workspace-id as xs:string) {
    
    let $log := xdmp:log(text{"$workspace-id: ", $workspace-id})
    
    (:run query against app services db:)
    let $eval :=  fn:concat(
            'xquery version "1.0-ml"; ',
            'declare namespace qconsole="http://marklogic.com/appservices/qconsole"; ',
            'cts:search(fn:doc()/qconsole:workspace, cts:element-value-query(xs:QName("qconsole:id"), "',
            xs:string($workspace-id),
            '"))')
    let $options := 
        <options xmlns="xdmp:eval">
            <database>{xdmp:database("App-Services")}</database> 
        </options>
      
    return xdmp:eval($eval, (), $options)    

};

declare function cw:insert-workspace($new-uri, $new-copy) {

  let $update-doc-output := xdmp:log("new-copy")
  let $update-doc-output := xdmp:log($new-copy)
  
    let $insert := 
        'xquery version "1.0-ml"; 
        declare namespace qconsole="http://marklogic.com/appservices/qconsole";
        declare variable $new-uri as xs:string external;
        declare variable $new-copy as node() external;
        xdmp:document-insert($new-uri, $new-copy)'
    
    (:run query against app services db:)
    let $options := 
        <options xmlns="xdmp:eval">
            <database>{xdmp:database("App-Services")}</database> 
        </options>
      
    let $eval := 
        xdmp:eval(
            $insert,
            (xs:QName("new-uri"), $new-uri, xs:QName("new-copy"), $new-copy),
            $options
        )
    
    return $eval
};

declare function cw:copy-text-query-doc($text-query-doc, $new-history-query-id){

  let $params :=  (xs:QName("text-query-doc"), $text-query-doc,
    xs:QName("new-history-query-id"), $new-history-query-id)
    
  let $eval := 
    'xquery version "1.0-ml";
    declare variable $text-query-doc external; 
    declare variable $new-history-query-id external; 
    let $new-uri := fn:concat("/queries/", $new-history-query-id, ".txt")
    return xdmp:document-insert($new-uri, $text-query-doc)'
    
    return xdmp:eval($eval, $params, $options)    
}; 

declare function cw:get-histories(
  $workspace-id as xs:string, 
  $history-query-id as xs:string, 
  $old-user-id as xs:string) {
  
  let $params :=  (
    xs:QName("workspace-id"), $workspace-id, 
    xs:QName("history-query-id"),  $history-query-id,
    xs:QName("old-user-id"), $old-user-id )
  
  let $eval := 
  'xquery version "1.0-ml";

  declare namespace qconsole="http://marklogic.com/appservices/qconsole";
  
  declare variable $workspace-id as xs:string external; 
  declare variable $history-query-id as xs:string external; 
  declare variable $old-user-id as xs:string external;
  
  let $history-query-id-q := cts:element-value-query(xs:QName("qconsole:id"), $history-query-id)
  let $history-query-id-element-q := cts:element-query(xs:QName("qconsole:query"), $history-query-id-q) 
  
  let $history-workspace-id-q := cts:element-value-query(xs:QName("qconsole:id"), $workspace-id)
  let $history-workspace-id-element-q := cts:element-query(xs:QName("qconsole:workspace"), $history-workspace-id-q) 
  
  let $history-security-userid-q := cts:element-value-query(xs:QName("qconsole:userid"), $old-user-id) 
  
  let $and-query := cts:and-query(($history-query-id-element-q, 
                                    $history-workspace-id-element-q, 
                                    $history-security-userid-q))  
                                    
  let $results := cts:search(doc()/qconsole:history, $and-query )
  
  return $results'          
  
  return xdmp:eval($eval, $params, $options)

};

declare function cw:copy-workspace($workspace){ 
    let $old-workspace := cw:get-workspace($workspace)
    let $current-user-id := fn:string(cu:get-user-id(xdmp:get-current-user()))
    return cw:copy($old-workspace, $current-user-id)

};
