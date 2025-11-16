using Microsoft.AspNetCore.Mvc;
using unifye_backend.DTO;
using unifye_backend.Interfaces;
using unifye_backend.Models;
using unifye_backend.Services;

namespace unifye_backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly IUserService _userService;
        private readonly IAuthService _authService;

        public UserController(IUserService userService, IAuthService authService)
        {
            this._userService = userService;
            this._authService = authService;
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

        public async Task<IActionResult> LoginUser([FromBody] LoginDTO loginDTO)
        {

            try
            {
                var user = await _userService.GetUserByEmail(loginDTO);

                if (user == null)
                {
                    return BadRequest("User does not exist");
                }

                return Ok();
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }

        }
    }
}
