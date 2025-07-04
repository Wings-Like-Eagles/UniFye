using Microsoft.AspNetCore.Mvc;
using unifye_backend.Interfaces;
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
            return Ok();
        }

        public User GetAllUsers()
        {
            var user = new User();


            return user;
        }
    }
}
