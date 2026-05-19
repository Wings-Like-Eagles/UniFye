// Repositories/IEventRepository.cs
using Unifye.Models;

namespace Unifye.Repositories;

public interface IEventRepository
{
    Task<IReadOnlyList<Event>> GetUpcomingAsync(int page, int pageSize, CancellationToken ct);
    Task<Event?> GetByIdAsync(Guid id, CancellationToken ct);
    Task AddAsync(Event ev, CancellationToken ct);
    void Delete(Event ev);                                          
    void AddAttendee(EventAttendee attendee);
    void RemoveAttendee(EventAttendee attendee);
    Task<EventAttendee?> GetAttendeeAsync(Guid eventId, Guid userId, CancellationToken ct);
    Task<IReadOnlyList<EventChatMessage>> GetChatMessagesAsync(
        Guid eventId, int page, int pageSize, CancellationToken ct);
    Task AddChatMessageAsync(EventChatMessage message, CancellationToken ct);
    Task SaveChangesAsync(CancellationToken ct);
}