import 'main.dart' as app;

void main() {
  app.main(
    baseUrlParam: 'http://10.0.2.2:5219',
    environmentParam: 'development', // environment name should match env file 
  );
}
