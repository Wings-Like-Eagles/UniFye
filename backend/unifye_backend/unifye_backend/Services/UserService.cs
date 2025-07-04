using System;
using unifye_backend.Interfaces;
using unifye_backend.Models;

namespace unifye_backend.Services
{
    public class UserService: IUserService
    {
        private readonly ApplicationDbContext _context;

        public UserService(ApplicationDbContext context)
        {
            _context = context;
        }

        public User GetUserById(int id)
        {
            return _context.Users.Find(id);
        }

        public IEnumerable<User> GetAllUsers()
        {
            return _context.Users.ToList();
        }

        public void CreateUser(User user)
        {
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
