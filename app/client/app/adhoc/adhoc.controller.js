'use strict';

angular.module('demoApp')
  .controller('AdhocCtrl', function ($scope, $http, Auth, User) {
    $http.get('/api/adhoc').success(function(data, status, headers, config) {
      $scope.database = data;
    });
  });
