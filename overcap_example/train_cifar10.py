import torch
import torch.distributed as distrib
import torch.nn.functional as F
import torchvision
import torchvision.transforms as T
import tqdm

from overcap_example.interruptible_utils import (
    EXIT,
    REQUEUE,
    get_requeue_state,
    init_handlers,
    save_and_requeue,
)

BATCH_SIZE = 128
LR = 1e-2
WD = 5e-3


def train_step(model, optimizer, batch, step):
    device = next(model.parameters()).device

    batch = tuple(v.to(device) for v in batch)
    x, y = batch

    logits = model(x)
    loss = F.cross_entropy(logits, y)

    optimizer.zero_grad()
    loss.backward()
    optimizer.step()

    # Add logging of train stats per step here!


def eval_epoch(model, dloader):
    device = next(model.parameters()).device

    eval_stats = torch.zeros((2,), device=device)
    for batch in dloader:
        batch = tuple(v.to(device) for v in batch)
        x, y = batch

        with torch.no_grad():
            logits = model(x)
            loss = F.cross_entropy(logits, y)

        eval_stats[0] += loss
        eval_stats[1] += (torch.argmax(logits, -1) == y).float().mean()

    eval_stats /= len(dloader)

    tqdm.tqdm.write(
        "Val:   Loss={:.3f}    Acc={:.3f}".format(
            eval_stats[0].item(), eval_stats[1].item()
        )
    )


def main():
    device = torch.device("cuda", 0)

    train_dset = torchvision.datasets.CIFAR10(
        "data", train=True, transform=T.ToTensor(), download=True
    )
    train_loader = torch.utils.data.DataLoader(
        train_dset, batch_size=BATCH_SIZE, shuffle=True, drop_last=True, num_workers=4
    )

    val_dset = torchvision.datasets.CIFAR10("data", train=False, transform=T.ToTensor())
    val_loader = torch.utils.data.DataLoader(
        val_dset, batch_size=BATCH_SIZE, shuffle=True, num_workers=4
    )

    model = torchvision.models.resnet18(pretrained=False, num_classes=10)
    model = model.to(device)

    optimizer = torch.optim.SGD(
        model.parameters(), lr=LR, momentum=0.9, nesterov=True, weight_decay=WD
    )

    start_step = 0
    total_steps = len(train_loader) * 300
    eval_every = len(train_loader)

    requeue_state = get_requeue_state()
    if requeue_state is not None:
        model.load_state_dict(requeue_state["model_state"])
        optimizer.load_state_dict(requeue_state["optim_state"])
        start_step = requeue_state["step"]

    train_batch_iter = iter(train_loader)
    for step in range(start_step, total_steps):
        try:
            batch = next(train_batch_iter)
        except StopIteration:
            train_batch_iter = iter(train_loader)
            batch = next(train_batch_iter)

        train_step(model, optimizer, batch, step)

        if ((step + 1) % eval_every) == 0:
            eval_epoch(model, val_loader)

        if EXIT.is_set():
            break

    if REQUEUE.is_set():
        save_and_requeue(
            dict(
                model_state=model.state_dict(),
                optim_state=optimizer.state_dict(),
                step=step,
            )
        )


if __name__ == "__main__":
    init_handlers()
    main()
