using Unifye.DTOs;

namespace Unifye.Services
{
    public interface IEventService
    {
        Task<AuthServiceResult<IReadOnlyList<EventSummaryResponse>>> GetEventsAsync(
            Guid currentUserId, int page, int pageSize, CancellationToken ct);

        Task<AuthServiceResult<EventDetailResponse>> GetEventAsync(
            Guid id, Guid currentUserId, CancellationToken ct);

        Task<AuthServiceResult<EventDetailResponse>> CreateEventAsync(
            Guid organiserId, CreateEventRequest request, CancellationToken ct);

        Task<AuthServiceResult<EventDetailResponse>> UpdateEventAsync(
            Guid id, Guid currentUserId, UpdateEventRequest request, CancellationToken ct);

        Task<AuthServiceResult<bool>> DeleteEventAsync(
            Guid id, Guid currentUserId, CancellationToken ct);

        Task<AuthServiceResult<bool>> JoinEventAsync(
            Guid id, Guid userId, CancellationToken ct);

        Task<AuthServiceResult<bool>> LeaveEventAsync(
            Guid id, Guid userId, CancellationToken ct);

        Task<AuthServiceResult<IReadOnlyList<EventChatMessageResponse>>> GetChatMessagesAsync(
            Guid eventId, Guid currentUserId, int page, int pageSize, CancellationToken ct);

        Task<AuthServiceResult<EventChatMessageResponse>> SendChatMessageAsync(
            Guid eventId, Guid senderId, SendChatMessageRequest request, CancellationToken ct);
    }
}
