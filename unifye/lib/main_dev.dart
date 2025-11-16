import 'main.dart' as app;

void main() {
  app.main(
    baseUrlParam: 'http://10.0.2.2:3000',
    environmentParam: 'development', // environment name should match env file 
  );
}
