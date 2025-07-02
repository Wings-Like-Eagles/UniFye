using Microsoft.AspNetCore.Mvc;
using unifye_backend.Models;

namespace unifye_backend.Controllers
{
    public class UserController : ControllerBase
    {
        private readonly IUserService _userService;

        public UserController(IUserService userService) 
        {
            _userService = userService;
        }
        public IActionResult Index()
        {
            return View();
        }

        public User GetAllUsers()
        {
            var user = new User(); 

        }
    }
}
