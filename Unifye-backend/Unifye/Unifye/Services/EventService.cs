// Services/EventService.cs
using Unifye.DTOs;
using Unifye.Models;
using Unifye.Repositories;

namespace Unifye.Services;

public class EventService(
    IEventRepository eventRepo,
    ILogger<EventService> logger) : IEventService
{
    private const int MaxMessageLength = 1000;

    // -------------------------------------------------------------------------
    // Queries
    // -------------------------------------------------------------------------

    public async Task<AuthServiceResult<IReadOnlyList<EventSummaryResponse>>> GetEventsAsync(
        Guid currentUserId, int page, int pageSize, CancellationToken ct)
    {
        var events = await eventRepo.GetUpcomingAsync(page, pageSize, ct);
        var result = events.Select(e => ToSummaryResponse(e, currentUserId)).ToList();
        return AuthServiceResult<IReadOnlyList<EventSummaryResponse>>.Ok(result);
    }

    public async Task<AuthServiceResult<EventDetailResponse>> GetEventAsync(
        Guid id, Guid currentUserId, CancellationToken ct)
    {
        var ev = await eventRepo.GetByIdAsync(id, ct);
        if (ev is null)
            return AuthServiceResult<EventDetailResponse>.Fail(
                StatusCodes.Status404NotFound, "Event not found.");

        return AuthServiceResult<EventDetailResponse>.Ok(ToDetailResponse(ev, currentUserId));
    }

    // -------------------------------------------------------------------------
    // Mutations
    // -------------------------------------------------------------------------

    public async Task<AuthServiceResult<EventDetailResponse>> CreateEventAsync(
        Guid organiserId, CreateEventRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Title))
            return AuthServiceResult<EventDetailResponse>.Fail(
                StatusCodes.Status400BadRequest, "Title is required.");

        if (request.StartsAtUtc <= DateTime.UtcNow)
            return AuthServiceResult<EventDetailResponse>.Fail(
                StatusCodes.Status400BadRequest, "Event must start in the future.");

        if (request.MaxAttendees is < 2)
            return AuthServiceResult<EventDetailResponse>.Fail(
                StatusCodes.Status400BadRequest, "Event must allow at least 2 attendees.");

        var ev = new Event
        {
            Id = Guid.NewGuid(),
            OrganiserId = organiserId,
            Title = request.Title.Trim(),
            Description = request.Description?.Trim(),
            StartsAtUtc = request.StartsAtUtc,
            EndsAtUtc = request.EndsAtUtc,
            MaxAttendees = request.MaxAttendees,
            LocationName = request.LocationName?.Trim(),
            LocationAddress = request.LocationAddress?.Trim(),
            LocationLatitude = request.LocationLatitude,
            LocationLongitude = request.LocationLongitude,
            CreatedAtUtc = DateTime.UtcNow,
        };

        ev.Attendees.Add(new EventAttendee
        {
            UserId = organiserId,
            JoinedAt = DateTime.UtcNow,
            IsOrganiser = true,
        });

        await eventRepo.AddAsync(ev, ct);
        await eventRepo.SaveChangesAsync(ct);

        logger.LogInformation("User {UserId} created event {EventId}", organiserId, ev.Id);

        var created = await eventRepo.GetByIdAsync(ev.Id, ct);
        return AuthServiceResult<EventDetailResponse>.Ok(ToDetailResponse(created!, organiserId));
    }

    public async Task<AuthServiceResult<EventDetailResponse>> UpdateEventAsync(
        Guid id, Guid currentUserId, UpdateEventRequest request, CancellationToken ct)
    {
        var ev = await eventRepo.GetByIdAsync(id, ct);
        if (ev is null)
            return AuthServiceResult<EventDetailResponse>.Fail(
                StatusCodes.Status404NotFound, "Event not found.");

        if (ev.OrganiserId != currentUserId)
            return AuthServiceResult<EventDetailResponse>.Fail(
                StatusCodes.Status403Forbidden, "Only the organiser can update this event.");

        if (!string.IsNullOrWhiteSpace(request.Title))
            ev.Title = request.Title.Trim();

        if (request.Description is not null)
            ev.Description = request.Description.Trim();

        if (request.StartsAtUtc.HasValue)
        {
            if (request.StartsAtUtc.Value <= DateTime.UtcNow)
                return AuthServiceResult<EventDetailResponse>.Fail(
                    StatusCodes.Status400BadRequest, "Event must start in the future.");

            ev.StartsAtUtc = request.StartsAtUtc.Value;
        }

        if (request.EndsAtUtc.HasValue)
            ev.EndsAtUtc = request.EndsAtUtc.Value;

        if (request.MaxAttendees.HasValue)
        {
            if (request.MaxAttendees.Value < ev.Attendees.Count)
                return AuthServiceResult<EventDetailResponse>.Fail(
                    StatusCodes.Status400BadRequest,
                    "Max attendees cannot be less than current attendee count.");

            ev.MaxAttendees = request.MaxAttendees.Value;
        }

        if (!string.IsNullOrWhiteSpace(request.LocationName))
            ev.LocationName = request.LocationName.Trim();

        if (!string.IsNullOrWhiteSpace(request.LocationAddress))
            ev.LocationAddress = request.LocationAddress.Trim();

        if (request.LocationLatitude.HasValue)
            ev.LocationLatitude = request.LocationLatitude.Value;

        if (request.LocationLongitude.HasValue)
            ev.LocationLongitude = request.LocationLongitude.Value;

        await eventRepo.SaveChangesAsync(ct);

        logger.LogInformation("User {UserId} updated event {EventId}", currentUserId, ev.Id);
        return AuthServiceResult<EventDetailResponse>.Ok(ToDetailResponse(ev, currentUserId));
    }

    public async Task<AuthServiceResult<bool>> DeleteEventAsync(
        Guid id, Guid currentUserId, CancellationToken ct)
    {
        var ev = await eventRepo.GetByIdAsync(id, ct);
        if (ev is null)
            return AuthServiceResult<bool>.Fail(StatusCodes.Status404NotFound, "Event not found.");

        if (ev.OrganiserId != currentUserId)
            return AuthServiceResult<bool>.Fail(
                StatusCodes.Status403Forbidden, "Only the organiser can delete this event.");

        eventRepo.Delete(ev);                           // was missing — caused silent no-op
        await eventRepo.SaveChangesAsync(ct);

        logger.LogInformation("User {UserId} deleted event {EventId}", currentUserId, id);
        return AuthServiceResult<bool>.Ok(true);
    }

    // -------------------------------------------------------------------------
    // Attendee management
    // -------------------------------------------------------------------------

    public async Task<AuthServiceResult<bool>> JoinEventAsync(
        Guid id, Guid userId, CancellationToken ct)
    {
        var ev = await eventRepo.GetByIdAsync(id, ct);
        if (ev is null)
            return AuthServiceResult<bool>.Fail(StatusCodes.Status404NotFound, "Event not found.");

        if (ev.StartsAtUtc <= DateTime.UtcNow)
            return AuthServiceResult<bool>.Fail(
                StatusCodes.Status400BadRequest, "Cannot join an event that has already started.");

        if (ev.Attendees.Any(a => a.UserId == userId))
            return AuthServiceResult<bool>.Fail(
                StatusCodes.Status409Conflict, "You have already joined this event.");

        if (ev.MaxAttendees.HasValue && ev.Attendees.Count >= ev.MaxAttendees.Value)
            return AuthServiceResult<bool>.Fail(
                StatusCodes.Status400BadRequest, "This event is full.");

        eventRepo.AddAttendee(new EventAttendee
        {
            EventId = id,
            UserId = userId,
            JoinedAt = DateTime.UtcNow,
            IsOrganiser = false,
        });

        await eventRepo.SaveChangesAsync(ct);

        logger.LogInformation("User {UserId} joined event {EventId}", userId, id);
        return AuthServiceResult<bool>.Ok(true);
    }

    public async Task<AuthServiceResult<bool>> LeaveEventAsync(
        Guid id, Guid userId, CancellationToken ct)
    {
        var ev = await eventRepo.GetByIdAsync(id, ct);
        if (ev is null)
            return AuthServiceResult<bool>.Fail(StatusCodes.Status404NotFound, "Event not found.");

        if (ev.OrganiserId == userId)
            return AuthServiceResult<bool>.Fail(
                StatusCodes.Status400BadRequest,
                "Organisers cannot leave their own event. Delete the event instead.");

        var attendee = await eventRepo.GetAttendeeAsync(id, userId, ct);
        if (attendee is null)
            return AuthServiceResult<bool>.Fail(
                StatusCodes.Status400BadRequest, "You are not attending this event.");

        eventRepo.RemoveAttendee(attendee);
        await eventRepo.SaveChangesAsync(ct);

        logger.LogInformation("User {UserId} left event {EventId}", userId, id);
        return AuthServiceResult<bool>.Ok(true);
    }

    // -------------------------------------------------------------------------
    // Chat
    // -------------------------------------------------------------------------

    public async Task<AuthServiceResult<IReadOnlyList<EventChatMessageResponse>>> GetChatMessagesAsync(
        Guid eventId, Guid currentUserId, int page, int pageSize, CancellationToken ct)
    {
        var ev = await eventRepo.GetByIdAsync(eventId, ct);
        if (ev is null)
            return AuthServiceResult<IReadOnlyList<EventChatMessageResponse>>.Fail(
                StatusCodes.Status404NotFound, "Event not found.");

        if (!ev.Attendees.Any(a => a.UserId == currentUserId))
            return AuthServiceResult<IReadOnlyList<EventChatMessageResponse>>.Fail(
                StatusCodes.Status403Forbidden, "Only attendees can view the chat.");

        var messages = await eventRepo.GetChatMessagesAsync(eventId, page, pageSize, ct);

        var result = messages
            .Reverse()
            .Select(ToChatMessageResponse)
            .ToList();

        return AuthServiceResult<IReadOnlyList<EventChatMessageResponse>>.Ok(result);
    }

    public async Task<AuthServiceResult<EventChatMessageResponse>> SendChatMessageAsync(
        Guid eventId, Guid senderId, SendChatMessageRequest request, CancellationToken ct)
    {
        var ev = await eventRepo.GetByIdAsync(eventId, ct);
        if (ev is null)
            return AuthServiceResult<EventChatMessageResponse>.Fail(
                StatusCodes.Status404NotFound, "Event not found.");

        if (!ev.Attendees.Any(a => a.UserId == senderId))
            return AuthServiceResult<EventChatMessageResponse>.Fail(
                StatusCodes.Status403Forbidden, "Only attendees can send messages.");

        if (string.IsNullOrWhiteSpace(request.Content))
            return AuthServiceResult<EventChatMessageResponse>.Fail(
                StatusCodes.Status400BadRequest, "Message content cannot be empty.");

        if (request.Content.Length > MaxMessageLength)
            return AuthServiceResult<EventChatMessageResponse>.Fail(
                StatusCodes.Status400BadRequest,
                $"Message cannot exceed {MaxMessageLength} characters.");

        var message = new EventChatMessage
        {
            Id = Guid.NewGuid(),
            EventId = eventId,
            SenderId = senderId,
            Content = request.Content.Trim(),
            SentAtUtc = DateTime.UtcNow,
        };

        await eventRepo.AddChatMessageAsync(message, ct);
        await eventRepo.SaveChangesAsync(ct);

        var saved = (await eventRepo.GetChatMessagesAsync(eventId, 1, 1, ct)).First();

        logger.LogInformation(
            "User {UserId} sent chat message in event {EventId}", senderId, eventId);

        return AuthServiceResult<EventChatMessageResponse>.Ok(ToChatMessageResponse(saved));
    }

    // -------------------------------------------------------------------------
    // Private mappers
    // -------------------------------------------------------------------------

    private static EventSummaryResponse ToSummaryResponse(Event ev, Guid currentUserId) => new()
    {
        Id = ev.Id,
        Title = ev.Title,
        Description = ev.Description,
        StartsAt = ev.StartsAtUtc,
        EndsAt = ev.EndsAtUtc,
        LocationName = ev.LocationName,
        LocationAddress = ev.LocationAddress,
        LocationLatitude = ev.LocationLatitude,
        LocationLongitude = ev.LocationLongitude,
        AttendeeCount = ev.Attendees.Count,
        MaxAttendees = ev.MaxAttendees,
        OrganiserId = ev.OrganiserId,
        OrganiserName = FullName(ev.Organiser),
        OrganiserImageUrl = ev.Organiser?.Profile?.ImageUrl,
        IsAttending = ev.Attendees.Any(a => a.UserId == currentUserId),
        CreatedAt = ev.CreatedAtUtc,
    };

    private static EventDetailResponse ToDetailResponse(Event ev, Guid currentUserId) => new()
    {
        Id = ev.Id,
        Title = ev.Title,
        Description = ev.Description,
        StartsAt = ev.StartsAtUtc,
        EndsAt = ev.EndsAtUtc,
        LocationName = ev.LocationName,
        LocationAddress = ev.LocationAddress,
        LocationLatitude = ev.LocationLatitude,
        LocationLongitude = ev.LocationLongitude,
        MaxAttendees = ev.MaxAttendees,
        OrganiserId = ev.OrganiserId,
        OrganiserName = FullName(ev.Organiser),
        OrganiserImageUrl = ev.Organiser?.Profile?.ImageUrl,
        IsAttending = ev.Attendees.Any(a => a.UserId == currentUserId),
        CreatedAt = ev.CreatedAtUtc,
        Attendees = ev.Attendees.Select(a => new EventAttendeeResponse
        {
            UserId = a.UserId,
            Name = FullName(a.User),
            ImageUrl = a.User?.Profile?.ImageUrl,
            IsOrganiser = a.IsOrganiser,
            JoinedAt = a.JoinedAt,
        }).ToList(),
    };

    private static EventChatMessageResponse ToChatMessageResponse(EventChatMessage m) => new()
    {
        Id = m.Id,
        EventId = m.EventId,
        SenderId = m.SenderId,
        SenderName = FullName(m.Sender),
        SenderImageUrl = m.Sender?.Profile?.ImageUrl,
        Content = m.Content,
        SentAt = m.SentAtUtc,
    };

    // Fixed: nullable User, null-safe profile access
    private static string FullName(User? user) =>
        user?.Profile is null
            ? string.Empty
            : $"{user.Profile.FirstName} {user.Profile.LastName}".Trim();
}
