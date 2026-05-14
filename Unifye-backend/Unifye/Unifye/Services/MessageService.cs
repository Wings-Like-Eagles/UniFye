using Unifye.Features.Messages.DTOs;
using Unifye.Features.Messages.Repositories;
using Unifye.Models;

namespace Unifye.Features.Messages.Services;

public class MessageService : IMessageService
{
    private readonly IMessageRepository _repository;

    public MessageService(IMessageRepository repository)
    {
        _repository = repository;
    }

    public async Task<MessageResponse> SendMessageAsync(
        Guid senderId,
        SendMessageRequest request)
    {
        var conversationExists =
            await _repository.ConversationExistsAsync(
                senderId,
                request.ReceiverId);

        if (!conversationExists)
        {
            await _repository.CreateConversationAsync(
                new Conversation
                {
                    Id = Guid.NewGuid(),
                    UserOneId = senderId,
                    UserTwoId = request.ReceiverId
                });
        }

        var message = new Message
        {
            Id = Guid.NewGuid(),
            SenderId = senderId,
            ReceiverId = request.ReceiverId,
            Content = request.Content,
            SentAt = DateTimeOffset.UtcNow
        };

        var created =
            await _repository.CreateAsync(message);

        return new MessageResponse
        {
            Id = created.Id,
            SenderId = created.SenderId,
            ReceiverId = created.ReceiverId,
            Content = created.Content,
            IsRead = created.IsRead,
            SentAt = created.SentAt
        };
    }

    public async Task<List<MessageResponse>> GetMessagesAsync(
        Guid currentUserId,
        Guid otherUserId)
    {
        var messages =
            await _repository.GetConversationMessagesAsync(
                currentUserId,
                otherUserId);

        return messages.Select(x => new MessageResponse
        {
            Id = x.Id,
            SenderId = x.SenderId,
            ReceiverId = x.ReceiverId,
            Content = x.Content,
            IsRead = x.IsRead,
            SentAt = x.SentAt
        }).ToList();
    }
}
