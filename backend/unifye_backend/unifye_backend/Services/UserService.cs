using System;
using unifye_backend.Interfaces;
using unifye_backend.Models;
using unifye_backend.Validators;

namespace unifye_backend.Services
{
    public class UserService: IUserService
    {
        private readonly ApplicationDbContext _context;
        private readonly IPasswordValidator _passwordValidator;

        public UserService(ApplicationDbContext context, IPasswordValidator passwordValidator)
        {
            _context = context;
            this._passwordValidator = passwordValidator;
        }

        public async Task<User> GetUserById(int id)
        {
            var user = await _context.Users.FindAsync(id) ?? throw new KeyNotFoundException($"User with ID {id} was not found.");
            return user;
        }

        public IEnumerable<User> GetAllUsers()
        {
            return _context.Users.ToList();
        }

        public void CreateUser(User user)
        {
            if (!_passwordValidator.Validate(user.Password, out var errors))
            {
                throw new ArgumentException(string.Join("; ", errors));
            }
            _context.Users.Add(user);
            _context.SaveChanges();
        }

        public void UpdateUser(User user)
        {
            var existing = _context.Users.Find(user.Id);
            if (existing != null)
            {
                existing.Name = user.Name;
                existing.Email = user.Email;
                // Update more properties
                _context.SaveChanges();
            }
        }

        public void DeleteUser(int id)
        {
            var user = _context.Users.Find(id);
            if (user != null)
            {
                _context.Users.Remove(user);
                _context.SaveChanges();
            }
        }
    }
}
