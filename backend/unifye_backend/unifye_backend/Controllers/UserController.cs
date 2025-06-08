using Microsoft.AspNetCore.Mvc;

namespace unifye_backend.Controllers
{
    public class UserController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Error() { }
    }
}
