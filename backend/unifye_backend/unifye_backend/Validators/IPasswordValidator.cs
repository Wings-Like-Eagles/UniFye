namespace unifye_backend.Validators
{
    public interface IPasswordValidator
    {
        bool Validate(string password, out List<string> errors);
    }
}
