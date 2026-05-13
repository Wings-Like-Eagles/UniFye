using Microsoft.EntityFrameworkCore;
using Unifye.Data;
using Unifye.Models;

namespace Unifye.Features.Messages.Repositories;

public class MessageRepository : IMessageRepository
{
    private readonly ApplicationDbContext _context;

    public MessageRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Message> CreateAsync(Message message)
    {
        _context.Messages.Add(message);

        await _context.SaveChangesAsync();

        return message;
    }

    public async Task<List<Message>> GetConversationMessagesAsync(
        Guid currentUserId,
        Guid otherUserId)
    {
        return await _context.Messages
            .Where(x =>
                (x.SenderId == currentUserId &&
                 x.ReceiverId == otherUserId) ||

                (x.SenderId == otherUserId &&
                 x.ReceiverId == currentUserId))
            .OrderBy(x => x.SentAt)
            .ToListAsync();
    }

    public async Task<bool> ConversationExistsAsync(
        Guid userOneId,
        Guid userTwoId)
    {
        return await _context.Conversations.AnyAsync(x =>
            (x.UserOneId == userOneId &&
             x.UserTwoId == userTwoId) ||

            (x.UserOneId == userTwoId &&
             x.UserTwoId == userOneId));
    }

    public async Task CreateConversationAsync(
        Conversation conversation)
    {
        _context.Conversations.Add(conversation);

        await _context.SaveChangesAsync();
    }
}
