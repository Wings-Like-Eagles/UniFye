namespace unifye_backend.Validators
{
    public class PasswordValidator
    {
        public bool Validate(string password, out List<string> errors)
        {
            errors = new List<string>();
            var passwordLength = password.Length;
            if (passwordLength <= 8)
            {
                errors.Add("Password is not long enough.");
            }
            if (!password.Any(char.IsUpper))
            {
                errors.Add("Password should contain at least one upper case letter");
            }
            if (!password.Any(char.IsDigit))
            {
                errors.Add("Password must contain at least one digit");
            }

            return errors.Count > 0;
        }
    }
}
