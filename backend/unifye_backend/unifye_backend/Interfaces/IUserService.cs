using unifye_backend.DTO;
using unifye_backend.Models;

namespace unifye_backend.Interfaces
{
    public interface IUserService
    {
        Task<User> GetUserById(int id);
        IEnumerable<User> GetAllUsers();
        Task<User> GetUserByEmail(LoginDTO loginDTO);
        void CreateUser(User user);
        void UpdateUser(User user);
        void DeleteUser(int id);
    }
}
