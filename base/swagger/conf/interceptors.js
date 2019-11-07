responseInterceptor: response => {
 \n
 const obj = response.obj;
 if (obj \&\& obj.swagger) {
  obj.securityDefinitions = {
   AuthorizationHeader:
    { name: "Authorization"
    , in:   "header"
    , type: "apiKey"
    , description: 'Submit value "Bearer $token", then execute the Introspection request, then click Explore button (top right).'
    }
  };
  obj.security = [{ AuthorizationHeader: [] }];
  response.text = JSON.stringify(obj);
  response.data = response.text;
 }
 \n
 return response;
},
requestInterceptor: request => {
 \n
 window.AuthorizationHeader = window.AuthorizationHeader \|\| request.headers.Authorization;
 request.headers.Authorization = request.headers.Authorization \|\| window.AuthorizationHeader;
 \n
 return request;
},
