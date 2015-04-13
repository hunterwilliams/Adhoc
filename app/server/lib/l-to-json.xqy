xquery version "1.0-ml";
module namespace to-json = "http://marklogic.com/ps/lib/to-json";

import module namespace json = "http://marklogic.com/xdmp/json"
    at "/MarkLogic/json/json.xqy";

declare function to-json:to-json($xml){
	let $custom :=
     let $config := json:config("custom")
     return 
       (map:put($config, "array-element-names",
                 ("text","point","value","operator-state",
                  "annotation","uri","qtext")),
        map:put($config, "element-namespace", 
                 "http://marklogic.com/appservices/search"),
        map:put($config, "element-namespace-prefix", "search"),
        map:put($config, "attribute-names",("warning","name")),
        map:put($config, "full-element-names",
                 ("query","and-query","near-query","or-query")),
        map:put($config, "json-children","queries"), 
        $config)        
    return 
        json:transform-to-json(
            $xml,
            $custom
        )
};