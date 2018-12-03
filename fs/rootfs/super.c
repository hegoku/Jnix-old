#include <system/fs.h>
#include <system/rootfs.h>
#include <string.h>
#include <sys/types.h>

static struct dir_entry *rootfs_mount(struct file_system_type *fs_type, int dev_num);
static int f_op_write(struct file_descriptor *fd, char *buf, int nbyte);
static int f_op_read(struct file_descriptor *fd, char *buf, int nbyte);

static int i_op_lookup(struct inode *base, const char *path, int len, struct inode **res_inode);

struct file_system_type rootfs_fs_type = {
    name: "rootfs",
    mount: rootfs_mount,
    next: NULL
};
struct file_operation rootfs_f_op={
    NULL,
    f_op_read,
    f_op_write,
    // 0,
    // 0,
    NULL,
    // 0,
    NULL,
    NULL,
    NULL
};
struct inode_operation rootfs_inode_op = {
    NULL,
    i_op_lookup,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
};

static struct dir_entry *rootfs_mount(struct file_system_type *fs_type, int dev_num)
{
    struct super_block *sb=get_block(0);
    fs_type->sb_table[fs_type->sb_num++] = sb;

    sb->fs_type = fs_type;

    struct inode *new_inode=get_inode();
    new_inode->sb=sb;
    new_inode->dev_num=sb->dev_num;
    new_inode->f_op=&rootfs_f_op;
    new_inode->inode_op = &rootfs_inode_op;
    new_inode->mode = FILE_MODE_DIR;

    struct dir_entry *new_dir=get_dir();
    new_dir->name[0]='/';
    new_dir->dev_num=sb->dev_num;
    new_dir->inode=new_inode;
    new_dir->parent=new_dir;
    new_dir->sb=sb;

    sb->root_dir=new_dir;
    sb->root_inode=new_inode;

    return new_dir;
}

void init_rootfs()
{
    register_filesystem(&rootfs_fs_type);
}

static int f_op_write(struct file_descriptor *fd, char *buf, int nbyte)
{
    return nbyte;
}

static int f_op_read(struct file_descriptor *fd, char *buf, int nbyte)
{
    return nbyte;
}

int i_op_lookup (struct inode *base, const char *path, int len,struct inode **res_inode)
{
    return 0;
}

// int i_op_mkdir (struct inode *, struct dentry *, int umode)
// {
//     struct inode *new_inode=get_inode();
//     new_inode->sb=inode->sb;
//     new_inode->dev_num=inode->dev_num;
//     new_inode->f_op=&rootfs_f_op;
//     new_inode->inode_op = &rootfs_inode_op;
//     new_inode->mode = FILE_MODE_DIR;

//     struct dir_entry *new_dir=get_dir();
//     memcpy(new_dir->name, name, len);
//     new_dir->dev_num=inode->dev_num;
//     new_dir->inode=new_inode;
//     new_dir->parent=new_dir;
//     new_dir->sb=inode->sb;
// }