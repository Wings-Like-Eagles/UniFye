using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi.Validations;
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
        public IActionResult RegisterUser(User newUser)
        {
            if (newUser == null)
            {
                return BadRequest();
            }

            try
            {
                _userService.CreateUser(newUser);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }

            return Ok();
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetUserById(int id)
        {
            User users = await _userService.GetUserById(id);
            return Ok(users);
        }
    }
}
