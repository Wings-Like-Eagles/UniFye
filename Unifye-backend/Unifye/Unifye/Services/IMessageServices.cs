using Unifye.Features.Messages.DTOs;

namespace Unifye.Features.Messages.Services;

public interface IMessageService
{
    Task<MessageResponse> SendMessageAsync(
        Guid senderId,
        SendMessageRequest request);

    Task<List<MessageResponse>> GetMessagesAsync(
        Guid currentUserId,
        Guid otherUserId);
}
