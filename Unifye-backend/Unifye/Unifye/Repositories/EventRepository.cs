// Repositories/EventRepository.cs
using Microsoft.EntityFrameworkCore;
using Unifye.Data;
using Unifye.Models;

namespace Unifye.Repositories;

public class EventRepository(ApplicationDbContext db) : IEventRepository
{
    public async Task<IReadOnlyList<Event>> GetUpcomingAsync(
        int page, int pageSize, CancellationToken ct)
    {
        return await db.Events
            .Where(e => e.StartsAtUtc > DateTime.UtcNow)
            .OrderBy(e => e.StartsAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Include(e => e.Organiser).ThenInclude(u => u.Profile)
            .Include(e => e.Attendees)
            .AsNoTracking()
            .ToListAsync(ct);
    }

    public async Task<Event?> GetByIdAsync(Guid id, CancellationToken ct)
    {
        return await db.Events
            .Include(e => e.Organiser).ThenInclude(u => u.Profile)
            .Include(e => e.Attendees).ThenInclude(a => a.User).ThenInclude(u => u.Profile)
            .FirstOrDefaultAsync(e => e.Id == id, ct);
    }

    public async Task AddAsync(Event ev, CancellationToken ct)
        => await db.Events.AddAsync(ev, ct);

    public void Delete(Event ev)
        => db.Events.Remove(ev);

    public void AddAttendee(EventAttendee attendee)
        => db.EventAttendees.Add(attendee);

    public void RemoveAttendee(EventAttendee attendee)
        => db.EventAttendees.Remove(attendee);

    public async Task<EventAttendee?> GetAttendeeAsync(
        Guid eventId, Guid userId, CancellationToken ct)
    {
        return await db.EventAttendees
            .FirstOrDefaultAsync(a => a.EventId == eventId && a.UserId == userId, ct);
    }

    public async Task<IReadOnlyList<EventChatMessage>> GetChatMessagesAsync(
        Guid eventId, int page, int pageSize, CancellationToken ct)
    {
        return await db.EventChatMessages
            .Where(m => m.EventId == eventId)
            .OrderByDescending(m => m.SentAtUtc) 
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Include(m => m.Sender).ThenInclude(u => u.Profile)
            .AsNoTracking()
            .ToListAsync(ct);
    }

    public async Task AddChatMessageAsync(EventChatMessage message, CancellationToken ct)
        => await db.EventChatMessages.AddAsync(message, ct);

    public async Task SaveChangesAsync(CancellationToken ct)
        => await db.SaveChangesAsync(ct);
}
