'use strict';

angular.module('demoApp')
  .controller('DetailCtrl', function ($scope, $http) {

    // Use the User $resource to fetch all users
    $scope.document = {permissions:[{'role':'test','method':'read'}],collections:['a','b'],document:'lots of text goes here'};
    $scope.database = 'Test';//$routeParams.database;
    $scope.uri      = 'document.xml';//$routeParams.uri;
  });
