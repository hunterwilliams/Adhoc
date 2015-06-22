'use strict';

angular.module('demoApp')
  .controller('NavbarCtrl', function ($scope, $location, Auth) {
    $scope.menu = [{
      'title': 'Home',
      'link': '/'
    }]
    $scope.dataExplorerMenu =[
    {
      'title': 'Adhoc',
      'link': '/adhoc'
    },
    {
      'title': 'Adhoc Wizard',
      'link': '/wizard'
    }];

    $scope.isCollapsed = true;
    $scope.isLoggedIn = Auth.isLoggedIn;
    $scope.isAdmin = Auth.isAdmin;
    $scope.isDataExplorer = Auth.isDataExplorer;
    $scope.getCurrentUser = Auth.getCurrentUser;

    $scope.logout = function() {
      Auth.logout();
      $location.path('/login');
    };

    $scope.isActive = function(route) {
      return route === $location.path();
    };
  });