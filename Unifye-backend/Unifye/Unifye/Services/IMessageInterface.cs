using Unifye.Models;

namespace Unifye.Features.Messages.Repositories;

public interface IMessageRepository
{
    Task<Message> CreateAsync(Message message);

    Task<List<Message>> GetConversationMessagesAsync(
        Guid currentUserId,
        Guid otherUserId);

    Task<bool> ConversationExistsAsync(
        Guid userOneId,
        Guid userTwoId);

    Task CreateConversationAsync(Conversation conversation);
}
