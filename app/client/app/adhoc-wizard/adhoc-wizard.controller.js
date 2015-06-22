'use strict';

angular.module('demoApp')
  .controller('AdhocWizardCtrl', function ($scope, $http, $sce) {

    $scope.step = 1;
    $scope.wizardForm;
    $scope.wizardResults = '';
    $scope.queryView = 'query';



    $scope.formInput = {};
    $scope.formInput.selectedDatabase = '';
    $scope.formInput.queryViewName = '';

    $scope.inputField = {};

    $scope.to_trusted = function(html_code) {
        return $sce.trustAsHtml(html_code);
    };

    // $http.get('/api/wizard/upload-form').success(function(data, status, headers, config) {
    //   if (status == 200){
    //     $scope.uploadForm = data;
    //   }
    // });

    $scope.wizardUploadFormData = null;

    $scope.changeFile = function(files) {
        if (files.length > 0){
            $scope.wizardUploadFormData = new FormData();
            //Take the first selected file
            $scope.wizardUploadFormData.append("uploadedDoc", files[0]);
        }
        else
        {
            $scope.wizardUploadFormData = null;
        }

    };

    $scope.upload = function(){
        if ($scope.wizardUploadFormData == null){
            alert('Please choose a file');
            return;
        }
        console.log("queryView:"+$scope.queryView);
        $scope.wizardUploadFormData.append('type',$scope.queryView);

        $http.post('/api/wizard/upload', $scope.wizardUploadFormData, {
            withCredentials: true,
            headers: {'Content-Type': undefined },
            transformRequest: angular.identity
        }).success(function(data, status){
                if (status == 200){
                    $scope.step = 2; 
                    $scope.wizardForm = data;
                }
            }).error(function(err){console.log('error');console.dir(err)});
    };

    $scope.getField = function(field) {
      var input = $scope.inputField[field];
      if (typeof(input) !== 'undefined' && input !== null)
      {
        return input;
      }
      else
      {
        return '';
      }
    };

    $scope.submitWizard = function(){
        var data = {};
        data.queryText = '';
        data.prefix = $scope.wizardForm.prefix;
        data.rootElement = $scope.wizardForm.rootElement;

        data.database = $scope.formInput.selectedDatabase;

        if ($scope.wizardForm.type.toLowerCase() === 'query'){
            data.queryName = $scope.formInput.queryViewName;

            for (var i = 1; i <= $scope.wizardForm.fields.length; i++){
                data['formLabel'+i] = $scope.getField(i);
                data['formLabelHidden'+i] = $scope.wizardForm.fields[i-1].xpathNormal;
            }
        }
        else
        {
            data.viewName = $scope.formInput.queryViewName;

            for (var i = 1; i <= $scope.wizardForm.fields.length; i++){
                data['columnName'+i] = $scope.getField(i);
                data['columnExpr'+i] = $scope.wizardForm.fields[i-1].xpathNormal;
            }
        }
        console.log('sending...');
        console.dir(data);
        $http.get('/api/wizard/create',{
            params:data
        }).success(function(data, status, headers, config) {
            $scope.wizardResults = data;
            $scope.step = 3;
        }).error(function(data, status){
            if (status == 500){
              $scope.wizardResults = "Server Error, please make changes and try again";
            }
        });
    };

  });
