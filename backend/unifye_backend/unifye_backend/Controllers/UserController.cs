using Microsoft.AspNetCore.Mvc;
using unifye_backend.Interfaces;
using unifye_backend.Models;

namespace unifye_backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly IUserService _userService;

        public UserController(IUserService userService)
        {
            this._userService = userService;
        }

        [HttpGet]
        public IActionResult GetAllUsers()
        {
            IEnumerable<User> users = _userService.GetAllUsers();


            return Ok(users);
        }

        [HttpPost]
        public IActionResult CreateUser(User newUser)
        {
            if(newUser == null)
            {
                return BadRequest();
            }

            _userService.CreateUser(newUser);

            return Ok();
        }
    }
}
