using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Unifye.DTOs;
using Unifye.Services;

namespace Unifye.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
[Produces("application/json")]
public class EventController(IEventService eventService) : ControllerBase
{
    // -------------------------------------------------------------------------
    // Events CRUD
    // -------------------------------------------------------------------------

    /// <summary>GET /api/event — List all upcoming events (paginated).</summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<EventSummaryResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetEvents(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var result = await eventService.GetEventsAsync(CurrentUserId, page, pageSize, cancellationToken);
        return result.Success ? Ok(result.Data) : ToError((IServiceResult)result);
    }

    /// <summary>GET /api/event/{id} — Full event detail with attendee list.</summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(EventDetailResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetEvent(Guid id, CancellationToken cancellationToken)
    {
        var result = await eventService.GetEventAsync(id, CurrentUserId, cancellationToken);
        return result.Success ? Ok(result.Data) : ToError((IServiceResult)result);
    }

    /// <summary>POST /api/event — Create a new event.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(EventDetailResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateEvent(
        [FromBody] CreateEventRequest request,
        CancellationToken cancellationToken)
    {
        var result = await eventService.CreateEventAsync(CurrentUserId, request, cancellationToken);
        if (!result.Success) return ToError((IServiceResult)result);

        return CreatedAtAction(nameof(GetEvent), new { id = result.Data!.Id }, result.Data);
    }

    /// <summary>PUT /api/event/{id} — Update event (organiser only).</summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(EventDetailResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateEvent(
        Guid id,
        [FromBody] UpdateEventRequest request,
        CancellationToken cancellationToken)
    {
        var result = await eventService.UpdateEventAsync(id, CurrentUserId, request, cancellationToken);
        return result.Success ? Ok(result.Data) : ToError((IServiceResult)result);
    }

    /// <summary>DELETE /api/event/{id} — Cancel event (organiser only).</summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteEvent(Guid id, CancellationToken cancellationToken)
    {
        var result = await eventService.DeleteEventAsync(id, CurrentUserId, cancellationToken);
        return result.Success ? NoContent() : ToError((IServiceResult)result);
    }

    // -------------------------------------------------------------------------
    // Attendee management
    // -------------------------------------------------------------------------

    /// <summary>POST /api/event/{id}/join — Join an event.</summary>
    [HttpPost("{id:guid}/join")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> JoinEvent(Guid id, CancellationToken cancellationToken)
    {
        var result = await eventService.JoinEventAsync(id, CurrentUserId, cancellationToken);
        return result.Success
            ? Ok(new { message = "Successfully joined the event." })
            : ToError((IServiceResult)result);
    }

    /// <summary>DELETE /api/event/{id}/leave — Leave an event.</summary>
    [HttpDelete("{id:guid}/leave")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> LeaveEvent(Guid id, CancellationToken cancellationToken)
    {
        var result = await eventService.LeaveEventAsync(id, CurrentUserId, cancellationToken);
        return result.Success
            ? Ok(new { message = "You have left the event." })
            : ToError((IServiceResult)result);
    }

    // -------------------------------------------------------------------------
    // Chat
    // -------------------------------------------------------------------------

    /// <summary>GET /api/event/{id}/chat — Paginated chat history.</summary>
    [HttpGet("{id:guid}/chat")]
    [ProducesResponseType(typeof(IReadOnlyList<EventChatMessageResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetChatMessages(
        Guid id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        var result = await eventService.GetChatMessagesAsync(
            id, CurrentUserId, page, pageSize, cancellationToken);

        return result.Success ? Ok(result.Data) : ToError((IServiceResult)result);
    }

    /// <summary>POST /api/event/{id}/chat — Send a chat message.</summary>
    [HttpPost("{id:guid}/chat")]
    [ProducesResponseType(typeof(EventChatMessageResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SendChatMessage(
        Guid id,
        [FromBody] SendChatMessageRequest request,
        CancellationToken cancellationToken)
    {
        var result = await eventService.SendChatMessageAsync(
            id, CurrentUserId, request, cancellationToken);

        return result.Success ? Ok(result.Data) : ToError((IServiceResult)result);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private Guid CurrentUserId
    {
        get
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier)
                        ?? throw new InvalidOperationException("User ID claim missing.");
            return Guid.Parse(claim);
        }
    }

    // Non-generic — only StatusCode and ErrorMessage are needed here.
    // Passes the message on 403 instead of swallowing it silently.
    private IActionResult ToError(IServiceResult result) =>
        result.StatusCode switch
        {
            StatusCodes.Status404NotFound => NotFound(new { message = result.ErrorMessage }),
            StatusCodes.Status403Forbidden => StatusCode(StatusCodes.Status403Forbidden, new { message = result.ErrorMessage }),
            StatusCodes.Status409Conflict => Conflict(new { message = result.ErrorMessage }),
            _ => BadRequest(new { message = result.ErrorMessage }),
        };
}