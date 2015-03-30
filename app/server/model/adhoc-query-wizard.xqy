xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config"
  at "/server/lib/config.xqy";
import module namespace render-view = "http://render-view"
  at "/server/view/render-view.xqy";
import module namespace create-adhoc = "http://create-adhoc-documents"
  at "/server/controller/create-adhoc-documents.xqy";


declare variable $NSMAP := 
  let $nsmap := map:map()
  let $_ := (
    map:put($nsmap, "test","t")
  )
  return $nsmap
;

declare function local:get-children-nodes($path, $node as node()) {
  let $results :=
  for $i in $node/node()
  let $ns := xs:string(fn:namespace-uri($i))
  let $root-ns-prefix := map:get($NSMAP,xs:string(fn:namespace-uri(fn:root($i))))
  let $ns-prefix := map:get($NSMAP, xs:string(fn:namespace-uri($i)))
  let $localname := fn:local-name($i)
  let $rootname := fn:local-name(fn:root($i))
  let $finalpath := if($path) then fn:concat($path, "/", $ns-prefix, ":", $localname)
                    else fn:concat($ns-prefix, ":", $localname)
  return 
    if($i/node()) then 
      (if ($i/node() instance of text()) then fn:substring(fn:concat("/", $root-ns-prefix, ":", $rootname, "/", $finalpath), 3) 
       else (), local:get-children-nodes($finalpath, $i)) 
       else ()
  return fn:distinct-values($results)
};

declare function local:render-fields($doc as node(), $type as xs:string) {
    let $label := if ($type eq "form") then "Form Field:" else "Column Name:"
    let $input1 := if ($type eq "form") then "formLabel" else "columnName"
    let $input2 := if ($type eq "form") then "formLabelHidden" else "columnExpr"
    return
    <div>{
      for $xpath at $p in local:get-children-nodes((), $doc)
      let $tokens := fn:tokenize($xpath, "/")
      return (
        <div>{($label, 
               <input type="text" name="{fn:concat($input1, $p)}"/>,
               <input type="hidden" name="{fn:concat($input2, $p)}" value="{fn:normalize-space(fn:tokenize($xpath, "--")[1])}"/>, 
               "&nbsp;&nbsp;", 
               local:collapse-xpath($xpath))}
        </div>, <br/>)
    }</div>
};

declare function local:collapse-xpath($xpath as xs:string){
  let $nodes := fn:tokenize($xpath, "/")
  let $nodescount := fn:count($nodes)
  let $new-xpath := 
    if ($nodescount eq 5) then 
      fn:string-join(($nodes[2], $nodes[3], "...", $nodes[last()]), "/")
    else if ($nodescount eq 6) then
      fn:string-join(($nodes[2], $nodes[3], "...", "...", $nodes[last()]), "/")      
    else $xpath
  return <span title="{$xpath}">{$new-xpath}</span>
};

let $uploaded-doc := xdmp:unquote(xdmp:get-request-field("uploadedDoc"))
let $type := xdmp:get-request-field("type")

let $type-label := if($type eq "query") then "Query" else "View"
let $query-view-name := if($type eq "query") then "queryName" else "viewName"

let $form := 
<form name="adhocquerywizardform"  action="/createnewqueryview"  method="post">
    <h2>{fn:concat("Edit Adhoc ", $type-label)}</h2>
    <div>
      <span>{fn:concat($type-label, " Name:")}</span>
      <input type="text" name="{$query-view-name}" size="20"/>
    </div>
    <br/>
    <h3>Document Name</h3>
    <div>
      <span>Root Element:</span>&nbsp;
      {fn:local-name($uploaded-doc/node())}
      <input type="hidden" name="rootElement" size="20" value="{fn:local-name($uploaded-doc/node())}"/>
    </div><br/>
    <h3>Database Name</h3>
    <div>
      <span>Database:</span>&nbsp;
      <select name="database">{ cfg:get-databases() }</select>
    </div><br/>
    <h3>Namespaces</h3>
    <div>prefix = namespace<br/><br/>{
        let $count := fn:count($cfg:NSBINDINGS)
        for $i in (1 to $count div 2)
        let $prefix := $cfg:NSBINDINGS[$i * 2 - 1]
        let $ns := $cfg:NSBINDINGS[$i * 2]
        let $label := fn:concat($prefix, " = ", $ns)
        return (<span>{$label}</span>,<br/>)
    }</div>    
     <input type="hidden" name="prefix" size="20" value="{map:get($NSMAP,xs:string(fn:namespace-uri($uploaded-doc/node())))}"/>
    <br/>{ 
    if ($type eq "query") then (
      <h3>Form</h3>,
      local:render-fields($uploaded-doc, "form"),
      <br/>)
    else  (
      <h3>View</h3>,
      local:render-fields($uploaded-doc, "view"))}
    <input type="submit" name="submit" value="Submit"/>
    <input type="hidden" name="queryText" value=""/>
</form>

return
  render-view:display("Adhoc Edit Query", $form)