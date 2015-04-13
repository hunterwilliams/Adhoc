'use strict';

angular.module('demoApp')
  .controller('DetailCtrl', function ($scope, $http) {

    // Use the User $resource to fetch all users
    $scope.doc = {type:'Test',permissions:[{'role':'test','method':'read'}],collections:['a','b'],text:'lots of text goes here',
      related:[
        {
          type:'Type A', items:[{uri:'abc.html',db:'Documents'}]
        }
      ]
    };
    $scope.database = 'Test';//$routeParams.database;
    $scope.uri      = 'document.xml';//$routeParams.uri;
  });
