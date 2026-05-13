using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Unifye.Features.Messages.DTOs;
using Unifye.Features.Messages.Services;

namespace Unifye.Features.Messages.Controllers;

[ApiController]
[Route("api/messages")]
[Authorize]
public class MessagesController : ControllerBase
{
    private readonly IMessageService _service;

    public MessagesController(
        IMessageService service)
    {
        _service = service;
    }

    [HttpPost]
    public async Task<IActionResult> SendMessage(
        [FromBody] SendMessageRequest request)
    {
        var userId = GetUserId();

        var response =
            await _service.SendMessageAsync(
                userId,
                request);

        return Ok(response);
    }

    [HttpGet("{otherUserId:guid}")]
    public async Task<IActionResult> GetMessages(
        Guid otherUserId)
    {
        var userId = GetUserId();

        var response =
            await _service.GetMessagesAsync(
                userId,
                otherUserId);

        return Ok(response);
    }

    private Guid GetUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier);

        return Guid.Parse(claim!.Value);
    }
}
