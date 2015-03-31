xquery version "1.0-ml";

import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";

xdmp:logout(),
render-view:display("Logout Result", <div><h1>Logged Out</h1><p>You are now logged out.</p></div>)
 